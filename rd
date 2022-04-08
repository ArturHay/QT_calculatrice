#include <lorawan.h>
#include <Arduino.h>
#include <SensirionI2CScd4x.h>
#include <Wire.h>
#include <string.h>
#include <stdio.h>
#define POWER_EN PB2

const sRFM_pins RFM_pins = {
  .CS = PA4,
  .RST = PB0,
  .DIO0 = PB14,
  .DIO1 = PB15,
  .DIO5 = -1
};

SensirionI2CScd4x scd4x;

void printUint16Hex(uint16_t value) {
    Serial.print(value < 4096 ? "0" : "");
    Serial.print(value < 256 ? "0" : "");
    Serial.print(value < 16 ? "0" : "");
    Serial.print(value, HEX);
}

void printSerialNumber(uint16_t serial0, uint16_t serial1, uint16_t serial2) {
    Serial.print("Serial: 0x");
    printUint16Hex(serial0);
    printUint16Hex(serial1);
    printUint16Hex(serial2);
    Serial.println();
}

void setup() 
{
  // put your setup code here, to run once:
delay(10000.);
Serial.println("Hello");

if(!lora.init())

  Serial.println("RFM95 not detected");
  
else

  Serial.println("RFM95 detected");
  
  //Choix de la classe à utiliser
  lora.setDeviceClass(CLASS_A);

  //Établir un canal aléatoire
  lora.setChannel(8);

  //Paramétrer le data rate pour SF7 BW 125KHz
  lora.setDataRate(5);

  //Mise en place des paramètres OTAA
  lora.setDevEUI("b7300d9f68b649de");
  lora.setAppEUI("0000000000000001");
  lora.setAppKey("2b75151628aed2a6abf7158809cf4f3c");

  //Procedure de jointure
  bool isJoined;
  do {
    Serial.println("Joining...");
    isJoined = lora.join();

    //Attente de 10sec avant de réessayer
    delay(1000);
  }while(!isJoined);
  Serial.println("Joined to network");

  Serial.begin(115200);
    while (!Serial) {
        delay(100);
    }
    
  pinMode(POWER_EN, OUTPUT);
  digitalWrite(POWER_EN, HIGH);

    Wire.begin();

    uint16_t error;
    char errorMessage[256];

    scd4x.begin(Wire);

    // stop potentially previously started measurement
    error = scd4x.stopPeriodicMeasurement();
    if (error) {
      
        Serial.print("Error trying to execute stopPeriodicMeasurement(): ");
        errorToString(error, errorMessage, 256);
        Serial.println(errorMessage);
    }

    uint16_t serial0;
    uint16_t serial1;
    uint16_t serial2;
    
    error = scd4x.getSerialNumber(serial0, serial1, serial2);
    if (error) {
      
        Serial.print("Error trying to execute getSerialNumber(): ");
        errorToString(error, errorMessage, 256);
        Serial.println(errorMessage);
        
    } else {
      
        printSerialNumber(serial0, serial1, serial2);
    }

    // Start Measurement
    error = scd4x.startPeriodicMeasurement();
    if (error) {
      
        Serial.print("Error trying to execute startPeriodicMeasurement(): ");
        errorToString(error, errorMessage, 256);
        Serial.println(errorMessage);
    }

    Serial.println("Waiting for first measurement... (5 sec)");
}
  
  

void loop() 
{
  
   uint16_t error;
    char errorMessage[256];

    delay(1000);

    // Read Measurement
    uint16_t co2;
    float temperature;
    float humidity;
    char str[80];
    int str_len;
    
    error = scd4x.readMeasurement(co2, temperature, humidity);
    if (error) {
      
        Serial.print("Error trying to execute readMeasurement(): ");
        errorToString(error, errorMessage, 256);
        Serial.println(errorMessage);
        
    } else if (co2 == 0) {
      
        Serial.println("Invalid sample detected, skipping.");
        
    } else {

    str_len = sprintf(str, "%d;%d.%02d;%d.%02d", co2, (int)temperature, (int)(temperature*100)%100, (int)humidity, (int)(humidity*100)%100) ;

    lora.sendUplink(str,str_len, 0, 0);
    
    }  
  delay(10000);
  lora.update();
}





void setup()
{
// put your setup code here, to run once:
delay(10000);
printf("hello");
if(!RN2483_initMAC())
  printf("RN2483 not detected");
else
  printf("RN2483 detected");

  //Procedure de jointure
  bool isJoined;
  do {
    printf("Joining...");
    isJoined = RN2483_join();

    //Attente de 5sec avant de réessayer
    delay(5000);
  }while(!isJoined);
  printf("Joined to network");
  RN2483_autobaud(115200);
  while(!RN2483_autobaud)
  {
      delay(1000);
  }
}


/*!
	@file	rn2483.c
	@author	Alexander Collins (alexander-collins@outlook.cm)
	@date	September 2017 - April 2018
	@brief	A library for embedded platforms that allows for interaction with a Microchip RN2483.

	@see rn2483.h
*/
//========
// MACROS
//========
//includes
#include "rn2483.h"


//===========
// FUNCTIONS
//===========
//PRIVATE
//! read a single byte from via UART from the RN2483
static uint8_t read()
{
}
//! write a string of bytes via UART to the RN2483
static void write(uint8_t *string)
{

}
// Converts buff into a string representation of it hexadecimal representation
static void get_hex_string(uint8_t *buff, int buff_len, char *ret)
{
    int j;  //index of buff
    int i;  //index of string
    uint8_t nibble;
    const char hex_map[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

    for (i = 0, j = 0; i < buff_len*2; i++)
    {
        nibble = 20;    // out of bounds of hex_map

        if (i % 2 == 0)
            nibble = (buff[j] >> 4) & 0x0F;
        else
        {
            nibble = buff[j] & 0x0F;
            j++;
        }

        ret[i] = hex_map[nibble];
    }

    return;
}
// Reads from the RX buffer into response until '\n' or EOB
static int RN2483_response(uint8_t *response)
{
	int i = 0;

	while (*response != '\n' && i < RN2483_MAX_BUFF)
	{
		*response++ = read();
		i++;
	}

    if (i <= 0)
        return RN2483_ERR_PANIC;
    else
        return i;
}

//PUBLIC
//system
// Resets the RN2483 by toggling the RESET pin
int RN2483_reset()
{
    /*
        implementation depends on platform?

        set RN2483 RESET pin HIGH
        set RN2483 RESET pin LOW
        set RN2483 RESET pin HIGH

        RN2483_response() to check response == success
    */
}
// Attempts to trigger the auto-baud detection sequence.
int RN2483_autobaud(int baud)
{
    /*
        implementation depends on platform?

        send break to RN2483
        set baud rate
        send 0x55

        check success with "sys get ver\r\n"
    */
}
// Sends a command to the RN2483 and sets the resposne in buffer
int RN2483_command(const char *command, char *response)
{


	//send command
	write((uint8_t*)command);

	//recv response
	if (RN2483_response((uint8_t *)response) != RN2483_ERR_PANIC)
        return RN2483_SUCCESS;
	else
        return RN2483_ERR_PANIC;
}
// Retrieves the firmware version of the RN2483 module and stores it in buff.
int RN2483_firmware(char *buff)
{
	return RN2483_command("sys get ver\r\n", buff);
}

//LoRa
// Initialises all the RN2483 MAC settings required to run LoRa commands (join, tx, etc).
int RN2483_initMAC()
{
	int ret = RN2483_ERR_PANIC;
    char response[RN2483_MAX_BUFF];

	do {
		ret++;
        response[0] = '\0';
		switch(ret)
		{
			case 0:	//reset MAC
				ret = RN2483_command("mac reset "LoRaWAN_Frequency "\r\n", response);
				break;
			case 1:	//set DevEui
				ret = RN2483_command("mac set deveui " LoRaWAN_DevEUI "\r\n", response);
				break;
			case 2:	//set AppEui
				ret = RN2483_command("mac set appeui " LoRaWAN_AppEUI "\r\n", response);
				break;
			case 3:	//set AppKey
				ret = RN2483_command("mac set appkey " LoRaWAN_AppKey "\r\n", response);
				break;
			case 4:	//set DataRate
				ret = RN2483_command("mac set dr " LoRaWAN_DataRate "\r\n", response);
				break;
            case 5: //save
                ret = RN2483_command("mac save\r\n", response);
                break;
		}
	} while (ret == RN2483_SUCCESS && strcmp(response, "ok\r\n") == 0);

	return ret;
}
// Attempts to join a LoRa network using the specified mode.
int RN2483_join()
{
	int ret = RN2483_ERR_PANIC;
    char response[RN2483_MAX_BUFF];
		ret = RN2483_command("mac join otaa\r\n", response);

    if (ret == RN2483_SUCCESS)
    {
        // if initial response success, wait for network response
        if (strcmp(response, "ok\r\n") == 0)
        {
            //@todo add delay here? -testing
            response[0] = '\0';
            if (RN2483_response((uint8_t *)response) != RN2483_ERR_PANIC)
                ret = (strcmp(response, "accepted\r\n")? RN2483_SUCCESS : RN2483_DENIED);
            else
                ret = RN2483_ERR_PANIC;
        }
        // else return err code
        else if (strcmp(response, "keys_not_init\r\n") == 0)
            ret = RN2483_ERR_KIDS;
        else if (strcmp(response, "no_free_ch\r\n") == 0)
            ret = RN2483_ERR_BUSY;
        else if (strcmp(response, "silent\r\n") == 0 || strcmp(response, "busy\r\n") == 0 || strcmp(response, "mac_paused\r\n") == 0)
            ret = RN2483_ERR_STATE;
	}

    return ret;
}
// Sends a confirmed/unconfirmed frame with an application payload of buff.
int RN2483_tx(const char *buff, bool confirm, char *downlink)
{
    int ret = RN2483_ERR_PANIC;
    char response[RN2483_MAX_BUFF];

    // figure out max payload length based on data rate
    int max_len = 0;
	if (strcmp(LoRaWAN_DataRate, "0") == 0 || strcmp(LoRaWAN_DataRate, "1") == 0 || strcmp(LoRaWAN_DataRate, "2") == 0)
		max_len = 59;
	else if (strcmp(LoRaWAN_DataRate, "3") == 0)
		max_len = 123;
	else if (strcmp(LoRaWAN_DataRate, "4") == 0 || strcmp(LoRaWAN_DataRate, "5") == 0 || strcmp(LoRaWAN_DataRate, "6") == 0 || strcmp(LoRaWAN_DataRate, "7") == 0)
		max_len = 230;
	else
		max_len = 230;

    // get payload
    char payload[strlen(buff)*2];   //1byte = 2hex
    get_hex_string((uint8_t *)buff, strlen(buff), payload); // see documentation notes on this

    // send command
    char cmd[max_len];
    if (confirm)
        sprintf(cmd, "mac tx cnf %s %s\r\n", LoRaWAN_Port, payload);
    else
        sprintf(cmd, "mac tx uncnf %s %s\r\n", LoRaWAN_Port, payload);
    ret = RN2483_command(cmd, response);

    if (ret == RN2483_SUCCESS)
    {
        // if initial response success, wait for tx success
        if (strcmp(response, "ok\r\n") == 0)
        {
            //@todo add delay here? -testing
            response[0] = '\0';
            if (RN2483_response((uint8_t *)response) != RN2483_ERR_PANIC)
            {
                if (strcmp(response, "mac_tx_ok\r\n") == 0)
                    ret = RN2483_NODOWN;
                else if (strcmp(response, "mac_err\r\n") == 0 || strcmp(response, "invalid_data_len\r\n") == 0)
                    ret = RN2483_ERR_PANIC;
                else //assume downlink data
                {
                    memcpy(downlink, response, strlen(response));
                    return RN2483_SUCCESS;
                }
            }
        }
        // else return err code
        else if (strcmp(response, "invalid_param\r\n") == 0)
            ret = RN2483_ERR_PARAM;
        else if (strcmp(response, "no_free_ch\r\n") == 0)
            ret = RN2483_ERR_BUSY;
        else if (strcmp(response, "not_joined\r\n") == 0 || strcmp(response, "frame_counter_err_rejoin_needed\r\n") == 0)
            ret = RN2483_ERR_JOIN;
        else if (strcmp(response, "silent\r\n") == 0 || strcmp(response, "busy\r\n") == 0 || strcmp(response, "mac_paused\r\n") == 0)
            ret = RN2483_ERR_STATE;
        else if (strcmp(response, "invalid_data_len\r\n") == 0)
            ret = RN2483_ERR_PANIC;
    }

    return ret;
}




/*!
	@file	rn2483.h
	@author	Alexander Collins (alexander-collins@outlook.com)
	@date	September 2017 - April 2018
	@brief	A library for embedded platforms that allows for interaction with a Microchip RN2483.

	@see https://www.microchip.com/wwwproducts/en/RN2483
	@see https://www.rs-online.com/designspark/rel-assets/ds-assets/uploads/knowledge-items/application-notes-for-the-internet-of-things/LoRaWAN%20Specification%201R0.pdf
*/

#ifndef RN2483
#define RN2483
//========
// MACROS
//========
//includes
// custom
#include "config.h"
// standard
#include <stdio.h>      //fgetc, fprintf
#include <string.h>     //strlen, strcmp
#include <stdint.h>     //uint8_t
#include <stdbool.h>    //bool
//defines
#define RN2483_MAX_BUFF	33 /**< Maximum(+1) number of characters returned by RN2483 responses */

//=========
// GLOBALS
//=========
//! Values returned by RN2483_* functions
enum RN2483_ReturnCodes {
	RN2483_SUCCESS,                 /**< Success */
	RN2483_ERR_PARAM,               /**< Error: invalid parameter passed to function */
	RN2483_EOB = RN2483_MAX_BUFF,	/**< Reached end of buffer passed to function */
    RN2483_ERR_KIDS,                /**< Error: tried to join a LoraWAN network without the correct keys & ids (kids) configured */
    RN2483_ERR_BUSY,                /**< Error: tried to join/tx but all configured frequency channels were busy, wait and try again */
    RN2483_ERR_STATE,               /**< Error: current state cannot perform action, see RN2483 documentation */
    RN2483_DENIED,                  /**< Join command went through, but the network denied your join request */
    RN2483_ERR_JOIN,                /**< Error: tried to tx data without being joined to a LoRaWAN network */
    RN2483_NODOWN,                  /**< tx succeeded and no downlink was received */
	RN2483_ERR_PANIC	            /**< Error: SOMETHING(???) went wrong. You found a bug! */
};
//! Valid LoRaWAN join modes @see RN2483_join(int mode)
enum RN2483_JoinModes {
    RN2483_OTAA,	/**< Over-the-Air-Activation */
	RN2483_ABP		/**< Activation-By-Personalization */
};

//===========
// FUNCTIONS
//===========
//system
//! Resets the RN2483 by toggling the RESET pin
/*!
	Toogles the reset pin (from HIGH -> LOW -> HIGH).

    The RN2483 module transmits it's firmware version upon being reset, so if the version is successful.

    @return RN2483_SUCCESS if version was succesfully retrieved after toggling the RESET pin
    @return RN2483_ERR_PANIC if version was not retrieved after toggling the RESET pin
*/
extern int RN2483_reset();
//! Attempts to trigger the auto-baud detection sequence.
/*!
    Triggers the autobaud detction sequence by sending a break, setting the baudrate and sending 0x55.

    The new baudrate is tested by attempting to retrieve the firmware version.

    @return RN2483_SUCCESS if RN2483_firmware() succeeded after autobaud.
    @return RN2483_ERR_PANIC if RN2483_firmware() failed after autobaud.
*/
extern int RN2483_autobaud(int baud);
//! Write a command to the RN2483 and recieve it's response
/*!
    Send a command to the RN2483, if the command is valid the RN2483's response will be written
    to response

    @return RN2483_ERR_PARAM if the command does not end in "\r\n" (required, see documentation)
    @return RN2483_SUCCESS command was successful and response was valid

    @see RN2483 LoRa Technology Module Command Reference User's Guide
*/
extern int	RN2483_command(const char *command, char *response);
//! Retrieves the firmware version of the RN2483 module and stores it in buff.
/*!
    If successful, buff should contain a string that looks like this:

        "RN2483 X.Y.Z MMM DD YYYY HH:MM:SS"

    where X.Y.Z is firmware version, MMM is month, DD is day, HH:MM:SS is hour, minutes, seconds.

        "sys get ver\r\n"

    @return RN2483_SUCCESS Successfully wrote the firmware version of RN2483 into response
    @return RN2483_ERR_PANIC Managed to read <= 0 bytes...
*/
extern int RN2483_firmware(char *buff);

//LoRa
//! Initialises all the RN2483 MAC settings required to run LoRa commands (join, tx, etc).
/*!
	Resets the software LoRaWAN stack and initialises all of the required parameters (set in
	config.h) to communicate over a LoRaWAN network.

	@return RN2483_SUCCESS The function reset & initialised all the required values without failure
	@return RN2483_ERR_PARAM Likely means memory issue was caused while reading a response from the
			RN2483
	@return RN2483_ERR_PANIC If this happens something went really wrong when writing a command
*/
extern int RN2483_initMAC();
//! Attempts to join a LoRa network using the specified mode.
/*!
	Sends out a request to join local LoRaWAN network in set mode, there are two responses from the
    RN2483 (handled by this function), the first detirmines whether the command was correct, the
    second detirmines whether the join request was successful.

    @see RN2483_JoinModes for valid mode values

    @return RN2483_ERR_PARAM Invalid mode parameter
    @return RN2483_ERR_PANIC Error reading response from the RN2384
    @return RN2483_ERR_KIDS Required keys & identifiers are not intialised
    @return RN2483_ERR_BUSY All configured frequency channels are currently busy, wait and try again
    @return RN2483_ERR_STATE Module cannot make join request in current state
    @return RN2483_DENIED Request went through, but the network denied your request
    @return RN2483_SUCCESS Successfully joined LoRaWAN network
*/
extern int RN2483_join();
//! Sends a confirmed/unconfirmed frame with an application payload of buff.
/*!
    Transmits data over a LoRa network in either confirmed or unconfirmed mode.

    @return RN2483_NODOWN Transmission was successful but the server sent no downlink data
    @return RN2483_ERR_PANIC Tx was a success, but the server sent an invalid downlink packet
    @return RN2483_SUCCESS Transmission was successful and downlink data was read into downlink
    @return RN2483_ERR_PARAM Invalid LoRaWAN_Port or invalid buff data
    @return RN2483_ERR_BUSY All channels are currently busy, try sending data less frequently
    @return RN2483_ERR_JOIN You need to join a LoRaWAN network to TX data over one
*/
extern int RN2483_tx(const char *buff, bool confirm, char *downlink);

#endif // RN2483




