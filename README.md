# underwater communication
Camera-Based Optical Communication System built for underwater communication
Built at hackenza 3.0

## Problem 
underwater wireless communication is very challenging in present times because water behaves very differently than air , generally we transmit and revieve radiowaves in order to communicate but when we try to do that underwater, because of the highly ionic salty water of ocean the radiowaves are absorbed quickly. Hence it is very difficult to exchange information using the the existing traditional methods to transfer information this repository suggests an alternate low cost method of communication using flashlight of a phone for transmission and the camera of other phone for recieving information 

## Solution 

our solution enables digital data transmission using a flashlight as the transmitter and a camera as the receiver. 
It implements custom encoding, synchronization, interleaving, and checksum validation to ensure reliable communication. we have two methods to do communication a fast method where you can quickly communicate using a dictionary of limited words and another slower but versatile method where you can tranfer any data. 

## Architecture

### Transmitter
- 5-bit character encoding
- Preamble generation
- Sync pattern insertion
- Payload construction
- Checksum generation
- Flashlight modulation (ON/OFF)

### Channel
- Visible light propagation
  

### Receiver
- Frame capture via camera
- Brightness detection
- Threshold decoding
- De-interleaving
- Checksum validation
- Message reconstruction

## Hardware Challenges

- Camera auto-exposure affecting brightness readings
- Rolling shutter causing partial-frame averaging
- Ambient light noise in dark environments
- Sensor saturation at high brightness levels

## explaination of every step in communication 

### - 5 bit encoding 
in this step the text entered on the app is converted into a 5bit format , conventional ASCII notations use 8bit but to make the communication faster we compressed it into a 5 bit system , this is how you create the payload 

### - preamble and sync 
we add a preamble in the beggining which is basically just string concatenation, this helps the reciever to idenitify that transmission is about to start , we have also added a sync to do the same purpose. preamble is a known sequence of bits sent at the start of a packet on the other hand sync To align the receiver’s clock and bit boundaries with the transmitter.

### - interleaving 
when we send the data underwater we get errors in bursts hence if before sending the data we shuffle it in a certain manner and the deshuffle it while recieving the error gets spread out instead of accumulating at one place 

### - checksum 
Checksum is used to detect errors in transmitted data.The sender calculates a small value (checksum) from the data and sends it along with the message.The receiver recalculates the checksum from the received data.If the calculated and received checksums match, the data is likely correct.If they don’t match, it means the data was corrupted during transmission.

### - manchester encoding 
we use manchester encoding while transmission to minimize the error and help the detection easily. after manchester encoding transmission part is over and the data is sent in the form of pulsating flashlight 

### - frame capture 
using manchester encoding the camera detects the varying intensity of the flashlight and uses a dynamic threshold which is regulated by the callibration done in the beggining , and converts the varying intensity into bits

### - majority voting 
frequency of flashlight due to hardware limitation is far less than the frequency of the camera capturing frames so for a particular information of bit multiple frames are captured . Suppose if 5 frames were captured for a particular bit , say '1' was supposed to be transmitted but due to noise 4 out of those 5 frames registered '1' and one frame registered '0' so majority voting will denote 1 for that particular frame 

### - deinterleaving 
once we have the data in binary now we deinterleave it to get the original sequence 

### - 5 bit de-encoder
now we have the data in binary so we can just de encode it and get the message transmitted 

### - padding 
while interleaving we need to add padding into the data because there is a depth of interleaving , the code divides the entire payload into groups equal to the depth of inteleaving say if it was 23 bit long data sequence then if the depth of interleaving is 4 then we will have 5 groups of 5 bits but in the end we will have a 6th group with just single bit , padding will complete the last group by adding extra zeros 









