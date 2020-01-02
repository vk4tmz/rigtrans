import java.util.Arrays;

import org.apache.commons.codec.DecoderException;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.lang3.StringUtils;

import com.fazecast.jSerialComm.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

public class Icom2Kenwood {

	private String gReadBuffer = "";

	public String readCommand(SerialPort portIn) {
		try {
			while (true) {
				// Check if GlboalReadBuffer contains a valid CMD sequence:
				// FEFE<CIV_ADDR_TX><CIV_ADDR_CONTROL><CMD_DATA>FE
				String patternString = "^FEFE(\\w\\w)(\\w\\w)(.*?)FD(.*)$";
				Pattern pattern = Pattern.compile(patternString);

				Matcher matcher = pattern.matcher(gReadBuffer);
				if (matcher.matches()) {
					System.out.println("Valid Command Sequence Available...");
					String civ_tx = matcher.group(1);
					String civ_ctrl = matcher.group(2);
					String cmd = matcher.group(3);
					
					// Update globalbuffer with any remaining unprocessed data;
					gReadBuffer = matcher.group(4);
					
					System.out.println(" [+] civ_tx:   [" + civ_tx + "]");
					System.out.println(" [+] civ_ctrl: [" + civ_ctrl + "]");
					System.out.println(" [+] cmd:      [" + cmd + "]");
					System.out.println(" [+] buf_rem:  [" + gReadBuffer + "]");
					
					// Lets return a OK MSG
					writeCmd(portIn, "FEFE" + civ_ctrl + civ_tx + "FBFD", true);
					
					// Have valid command let return it for translation
					return cmd;
				}

				// Attempt to read more data to build globalReadBuffer
				byte[] readBuffer = new byte[1024];
				int numRead = portIn.readBytes(readBuffer, readBuffer.length);
				if (numRead > 0) {
					System.out.println("Read " + numRead + " bytes.");
					byte[] buf = Arrays.copyOf(readBuffer, numRead);
					String bufHex = Hex.encodeHexString(buf).toUpperCase();
					System.out.println("Data: [" + bufHex + "]");
					gReadBuffer += bufHex;
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}

		return "";
	}

	private void writeCmd(SerialPort portIn, String cmd, boolean convertFromHex) {
		try {
			byte buf[] = null;
			if (convertFromHex) {
				buf = Hex.decodeHex(cmd);
			} else {
				buf = cmd.getBytes();
			}
			System.out.println("Sending Cmd: [" + cmd + "].  Length: " + buf.length);
			portIn.writeBytes(buf, buf.length);
			System.out.println("CMD Sent.");
		} catch (DecoderException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		
	}

	public void translate(String comPortInName, String comPortOutName) {

		SerialPort comPortIn = SerialPort.getCommPort(comPortInName);
		comPortIn.openPort();
		comPortIn.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 100, 0);

		SerialPort comPortOut = SerialPort.getCommPort(comPortOutName);
		comPortOut.openPort();
		comPortOut.setComPortTimeouts(SerialPort.TIMEOUT_READ_SEMI_BLOCKING, 100, 0);

		try {
			while (true) {
				String cmd = readCommand(comPortIn);
				System.out.println(" Processing CMD: [" + cmd + "]");
				String patternString = "^(\\d\\d)(\\d\\d)(.*)";
				Pattern pattern = Pattern.compile(patternString);

				Matcher matcher = pattern.matcher(cmd);
				if (matcher.matches()) {
					System.out.println("Valid Command Sequence Available...");
					String cn = matcher.group(1);
					String sc = matcher.group(2);
					String data = matcher.group(3);
					
					switch (cn) {
					case "05": {
						data = sc + data;
						//String freqStr = StringUtils.reverse(data);
						StringBuilder freqStrB = new StringBuilder();
						freqStrB.append(data.substring(8, 10));
						freqStrB.append(data.substring(6, 8));
						freqStrB.append(data.substring(4, 6));
						freqStrB.append(data.substring(2, 4));
						
						// Substract 600hz
						int freq = Integer.parseInt(freqStrB.toString());
						freq = freq - 6;
						String freqStr = Integer.toString(freq);
						freqStr = StringUtils.leftPad(freqStr, 8, "0");

						System.out.println("  [+] Freq: " + freqStr);
	
						// TS2000 Set VFOA Freq to 7 MHz
						// FA00007000000;
						
						String kw_freq_cmd = "FA00" + freqStr + "00;";
						System.out.println("Sending Kenwood CMD");
						writeCmd(comPortOut, kw_freq_cmd, false);
						
						break;
					}
					default:
						System.out.println("  [+] Unhandled Command : [" + cn + "] skipping...");
					}
				} 
				else
				{
					System.out.println("  [+] Invalid CMD Skipped...");
				}
					
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			comPortIn.closePort();
			comPortOut.closePort();
		}
	}

	public static void listSerialPorts() {
		System.out.println("Available Serial Ports");
		SerialPort[] ports = SerialPort.getCommPorts();
		for (SerialPort serialPort : ports) {
			System.out.println(" [+] Port: " + serialPort.getSystemPortName());
		}
	}

	public static void main(String[] args) {

		Icom2Kenwood i2k = new Icom2Kenwood();
		i2k.translate("COM10", "COM11");

	}

}
