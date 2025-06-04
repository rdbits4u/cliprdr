
#ifndef _LIBCLIPRDR_H
#define _LIBCLIPRDR_H

#include <stdint.h>

#define LIBCLIPRDR_ERROR_NONE           0
#define LIBCLIPRDR_ERROR_MEMORY         -1
#define LIBCLIPRDR_ERROR_SEND_DATA      -2
#define LIBCLIPRDR_ERROR_PROCESS_DATA   -3
#define LIBCLIPRDR_ERROR_PARSE          -4
#define LIBCLIPRDR_ERROR_READY          -5
#define LIBCLIPRDR_ERROR_SEND_CAPS      -6
#define LIBCLIPRDR_ERROR_FORMAT_LIST    -7

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
                       uint32_t num_formats,
                       struct cliprdr_format_t* formats);
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

#endif
