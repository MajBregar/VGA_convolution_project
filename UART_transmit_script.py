import serial
import time

def uart_transmitter(port, baud_rate, messages, send_delay = 0.01, verbose=False):
    try:
        i = 0

        N= len(messages)
        percentN = N / 100
        next_thr = percentN
        progress = 0
        

        with serial.Serial(port, baud_rate, timeout=1) as ser:
            for message in messages:
                ser.write(bytes([message]))
                i += 1
                if (verbose == True):
                    #print(f"Message sent: {bin(message)} on address {bin(i)}")
                    if (i > next_thr):
                        next_thr += percentN
                        progress += 1
                        print(f"progress: {progress}%")

                time.sleep(send_delay)
        
        if (verbose == True):
            print(f"progress: 100%")

    except serial.SerialException as e:
        print(f"Error opening or writing to the serial port: {e}")

if __name__ == "__main__":
    com_port = "COM4"
    baud_rate = 19200

    data_messages = [255 for i in range(153600)]

    uart_transmitter(com_port, baud_rate, data_messages, send_delay=0.0001, verbose=True)
