#import <MulleCA/MulleCA.h>
int main(void) {
   mulle_printf("CAAnimation ivars: _relative offset in struct\n");
   mulle_printf("sizeof mulle_relativetimerange: %zu\n", sizeof(struct mulle_relativetimerange));
   mulle_printf("sizeof CAAnimationMutableState: %zu\n", sizeof(struct CAAnimationMutableState));
   mulle_printf("sizeof CAAnimationStorage: %zu\n", sizeof(struct CAAnimationStorage));
   mulle_printf("sizeof mulle_pointerarray: %zu\n", sizeof(struct mulle_pointerarray));
   return 0;
}
