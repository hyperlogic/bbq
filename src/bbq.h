#ifndef BBQ_H
#define BBQ_H

#ifdef __cplusplus
extern "C" {
#endif

void* bbq_load(const char* filename);
void bbq_free(void* ptr);

#ifdef __cplusplus
}
#endif


#endif
