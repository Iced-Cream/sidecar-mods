// Plaits' user_data.h replaced for the Sidecar's PLAITS blob: no stored user data (Plaits' own reads custom wavetables
// and DX7 banks from an STM32 flash address). Every engine plays its ROM data.
#ifndef PLAITS_USER_DATA_H_
#define PLAITS_USER_DATA_H_
#include <stddef.h>
#include <stdint.h>
namespace plaits {
class UserData {
 public:
  enum { SIZE = 0x1000 };
  inline const uint8_t* ptr(int slot) const { (void)slot; return NULL; }
  inline bool Save(uint8_t* rx_buffer, int slot) { (void)rx_buffer; (void)slot; return false; }
};
}  // namespace plaits
#endif
