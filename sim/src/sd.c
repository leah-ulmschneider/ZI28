#include "sd.h"

//SdCard::SdCard(char* fileName) {
//	imgFile = fopen(fileName, "rb");
//	status = IDLE;
//}

//SdCard::~SdCard() {
//	fclose(imgFile);
//}

unsigned char SdCard_transfer(struct SdCard *card, unsigned char in) {
	unsigned char out = 0xff;
	if (card->enable) {
		switch (card->status) {
			case IDLE:
				if ((in & 0xc0) != 0x40)
					break;
				card->status = COMMAND;
				card->count = 0;
			case COMMAND:
				card->commandFrame[card->count] = in;
				card->count++;
				if (card->count >= 6) {
					SdCard_parseCommand(card);
				}
				break;
			case RESPONSE:
				out = card->response;
				card->status = IDLE;
				break;
			case READ_RESPONSE:
				out = card->response;
				card->status = READ;
				card->count = 0;
				break;
			case READ:
				if ((in & 0xc0) == 0x40) {
					card->status = COMMAND;
					card->count = 0;
				} else {
					if (card->count == 0) {
						// Data token
						out = 0xfe;
						card->count++;
					} else if (card->count > card->blockLen + 2) {
						card->count = 0;
						out = 0xff;
					} else if (card->count > card->blockLen) {
						// CRC, not calculated
						out = 0xff;
						card->count++;
					} else {
						out = fgetc(card->imgFile);
						card->count++;
					}
				}
				break;
			case WRITE:
				break;
			default:
				break;
		}
	}
	return out;
}

void SdCard_setCS(struct SdCard *card, int state) {
	if (!card->enable && state) {
		card->status = IDLE;
	}
	card->enable = state;
}

void SdCard_parseCommand(struct SdCard *card) {
	unsigned char command = card->commandFrame[0] & 0x3f;
	unsigned int argument;

	argument = card->commandFrame[4];
	argument += card->commandFrame[3] << 8;
	argument += card->commandFrame[2] << 16;
	argument += card->commandFrame[1] << 24;

	switch (command) {
		case GO_IDLE_STATE:
			card->response = 0x01;
			card->status = RESPONSE;
			break;
		case SEND_OP_COND:
			card->response = 0x00;
			card->status = RESPONSE;
			break;
		case STOP_TRANSMISSION:
			card->response = 0x00;
			card->status = RESPONSE;
			break;
		case SET_BLOCKLEN:
			card->blockLen = argument;
			card->response = 0x00;
			card->status = RESPONSE;
			break;
		case READ_MULTIPLE_BLOCK:
			fseek(card->imgFile, argument, SEEK_SET);
			card->response = 0x00;
			card->status = READ_RESPONSE;
			break;
		default:
			break;
	}
}




//SdModule::SdModule(SdCard& c) {
//	card = &c;
//}

void SdModule_write(struct SdModule *module, unsigned short addr, unsigned char data) {
	switch (addr) {
		case 0:
			module->writeReg = data;
			break;
		case 1:
			module->readReg = SdCard_transfer(module->card, module->writeReg);
			module->writeReg = 0xff;
			break;
		case 2:
			SdCard_setCS(module->card, 1);
			break;
		case 3:
			SdCard_setCS(module->card, 0);
			break;
		default:
			break;
	}
	return;
}

unsigned char SdModule_read(struct SdModule *module, unsigned short addr) {
	unsigned char data = 0xff;
	switch (addr) {
		case 0:
			data = module->readReg;
			break;
		default:
			break;
	}
	return data;
}