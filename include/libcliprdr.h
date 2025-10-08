
#ifndef _LIBCLIPRDR_H
#define _LIBCLIPRDR_H

#include <stdint.h>

#define LIBCLIPRDR_ERROR_NONE                   0
#define LIBCLIPRDR_ERROR_MEMORY                 -1
#define LIBCLIPRDR_ERROR_SEND_DATA              -2
#define LIBCLIPRDR_ERROR_PROCESS_DATA           -3
#define LIBCLIPRDR_ERROR_PARSE                  -4
#define LIBCLIPRDR_ERROR_READY                  -5
#define LIBCLIPRDR_ERROR_SEND_CAPS              -6
#define LIBCLIPRDR_ERROR_FORMAT_LIST            -7
#define LIBCLIPRDR_ERROR_FORMAT_LIST_RESPONSE   -8
#define LIBCLIPRDR_ERROR_DATA_REQUEST           -9
#define LIBCLIPRDR_ERROR_DATA_RESPONSE          -10
#define LIBCLIPRDR_ERROR_LOG                    -11


#define CB_RESPONSE_OK      0x0001
#define CB_RESPONSE_FAIL    0x0002
#define CB_ASCII_NAMES      0x0004

#define CF_TEXT                        1
#define CF_BITMAP                      2
#define CF_METAFILEPICT                3
#define CF_SYLK                        4
#define CF_DIF                         5
#define CF_TIFF                        6
#define CF_OEMTEXT                     7
#define CF_DIB                         8
#define CF_PALETTE                     9
#define CF_PENDATA                     10
#define CF_RIFF                        11
#define CF_WAVE                        12
#define CF_UNICODETEXT                 13
#define CF_ENHMETAFILE                 14
#define CF_HDROP                       15
#define CF_LOCALE                      16
#define CF_MAX                         17
#define CF_OWNERDISPLAY                128
#define CF_DSPTEXT                     129
#define CF_DSPBITMAP                   130
#define CF_DSPMETAFILEPICT             131
#define CF_DSPENHMETAFILE              142
#define CF_PRIVATEFIRST                512
#define CF_PRIVATELAST                 767
#define CF_GDIOBJFIRST                 768
#define CF_GDIOBJLAST                  1023

struct cliprdr_format_t
{
    uint32_t format_id;
    uint32_t format_name_bytes;
    void* format_name;
};

struct cliprdr_t
{
    int (*log_msg)(struct cliprdr_t* cliprdr, const char* msg);
    int (*send_data)(struct cliprdr_t* cliprdr, uint16_t channel_id,
                     void* data, uint32_t bytes);
    int (*ready)(struct cliprdr_t* cliprdr, uint16_t channel_id,
                 uint32_t version, uint32_t general_flags);
    int (*format_list)(struct cliprdr_t* cliprdr, uint16_t channel_id,
                       uint16_t msg_flags, uint32_t num_formats,
                       struct cliprdr_format_t* formats);
    int (*format_list_response)(struct cliprdr_t* cliprdr,
                                uint16_t channel_id, uint16_t msg_flags);
    int (*data_request)(struct cliprdr_t* cliprdr, uint16_t channel_id,
                        uint32_t requested_format_id);
    int (*data_response)(struct cliprdr_t* cliprdr, uint16_t channel_id,
                         uint16_t msg_flags, void* requested_format_data,
                         uint32_t requested_format_data_bytes);
    void* user;
};

int cliprdr_init(void);
int cliprdr_deinit(void);
int cliprdr_create(struct cliprdr_t** cliprdr);
int cliprdr_delete(struct cliprdr_t* cliprdr);
int cliprdr_process_data(struct cliprdr_t* cliprdr, uint16_t channel_id,
                         void* data, uint32_t bytes);
int cliprdr_send_capabilities(struct cliprdr_t* cliprdr, uint16_t channel_id,
                              uint32_t version, uint32_t general_flags);

int cliprdr_send_format_list(struct cliprdr_t* cliprdr, uint16_t channel_id,
                             uint16_t msg_flags, uint32_t num_formats,
                             struct cliprdr_format_t* formats);
int cliprdr_send_format_list_response(struct cliprdr_t* cliprdr,
                                      uint16_t channel_id,
                                      uint16_t msg_flags);
int cliprdr_send_data_request(struct cliprdr_t* cliprdr, uint16_t channel_id,
                              uint32_t requested_format_id);
int cliprdr_send_data_response(struct cliprdr_t* cliprdr, uint16_t channel_id,
                               uint16_t msg_flags,
                               void* requested_format_data,
                               uint32_t requested_format_data_bytes);
                              
#endif
