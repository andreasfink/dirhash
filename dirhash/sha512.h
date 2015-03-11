//
//  sha512.h
//  dirhash
//
//  this is a stripped down version from mbed TLS (https://polarssl.org)
//
/*
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */


#include <string.h>
#include <inttypes.h>
#define UL64(x) x##ULL

#define     SHA512_DIGEST_LENGTH    64
/**
 *  SHA-512 context structure
 */
typedef struct sha512_context
{
    uint64_t total[2];          /*!< number of bytes processed  */
    uint64_t state[8];          /*!< intermediate digest state  */
    unsigned char buffer[128];  /*!< data block being processed */
    unsigned char ipad[128];    /*!< HMAC: inner padding        */
    unsigned char opad[128];    /*!< HMAC: outer padding        */
} sha512_context;

void sha512_init(sha512_context *ctx);
void sha512_free(sha512_context *ctx);
void sha512_starts( sha512_context *ctx);
void sha512_update( sha512_context *ctx, const unsigned char *input, size_t ilen);
void sha512_finish( sha512_context *ctx, unsigned char output[SHA512_DIGEST_LENGTH]);
void sha512(const unsigned char *input,size_t ilen, unsigned char output[SHA512_DIGEST_LENGTH]);


