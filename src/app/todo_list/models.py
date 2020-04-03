from django.db import models

import hashlib
import json
import time

def generate_key():
    hash_function = hashlib.sha1()
    hash_function.update(str(time.time()).encode('utf8'))
    return  hash_function.hexdigest()

# Create your models here.
class ToDoList(models.Model):
    key = models.CharField(max_length=40, default=generate_key)
    email = models.EmailField()
    to_do_list = models.TextField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'to_do_list'

    def save(self, force_insert=False, force_update=False, using=None, update_fields=None):
        if isinstance(self.to_do_list, list):
            self.to_do_list = json.dumps(self.to_do_list)

        return super().save(force_insert=force_insert, force_update=force_update, using=using, update_fields=update_fields)

    def get_list(self):
        return json.loads(self.to_do_list)