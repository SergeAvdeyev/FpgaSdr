#include "system.h"
#include "drivers/inc/altera_avalon_pio_regs.h" //управление GPIO
#include "alt_types.h" //простые типы данных
#include "sys/alt_stdio.h" //замена stdio.h

int main (void)
{
	alt_u32 freq_phrase = 0x91687; //90E02 - 7.04 91687 - 7.1
	alt_u32 freq_phrase_tmp;
	alt_u8 mode=0; //0-LSB 1-USB

	alt_u8 command=0;

	IOWR_ALTERA_AVALON_PIO_DATA(PIO_FREQ_PHRASE_BASE, freq_phrase);
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_MODE_BASE, mode);
	while (1)
	{
		command=alt_getchar(); //получаем команду от ардуино
		switch (command)
		{
		case 0x05: //команда получения текущей фразы частоты
			alt_printf("%x\n",freq_phrase);
			break;
		case 0x06: //команда задания текущей фразы частоты
			freq_phrase_tmp=alt_getchar()<<24;
			freq_phrase_tmp+=(alt_getchar()<<16);
			freq_phrase_tmp+=(alt_getchar()<<8);
			freq_phrase_tmp+=alt_getchar();
			freq_phrase=freq_phrase_tmp;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FREQ_PHRASE_BASE, freq_phrase);
			alt_printf("%x\n",freq_phrase);
			break;
		case 0x07: //команда получения текущей моды
			alt_printf("%c",mode);
			break;
		case 0x08: //команда задания текущей моды
			mode=alt_getchar();
			if(mode>1 || mode<0) mode=0;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_MODE_BASE, mode);
			alt_printf("%c",mode);
			break;
		default:
			alt_printf("command not defined\n");
			break;
		}
	}
	return 0;
}
