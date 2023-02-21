#include <stdio.h>

typedef struct node_s {
    void          *data;
    struct node_s *next;
    struct node_s *prev;
} Node;

struct list_s {
    size_t  size;
    Node   *head;
    Node   *tail;
};

int list_get_first(struct list_s *list, void **out)
{
    if (list->size == 0) 
        return -1;

    *out = list->head->data; 
    return 1;
}
