from django.test import TestCase

import json

from ..models import ToDoList

class TestToDoListModel(TestCase):
    fixtures = ['test_data.json']

    def test_create_instance(self):
        self.to_do_list = [
            'ToDo1',
            'ToDo2',
            'ToDo3'
        ]
        self.email = 'test@gmail.com'
        new_instance = ToDoList.objects.create(
            email=self.email,
            to_do_list=self.to_do_list
        )
        new_instance.save()
        self.hash_key = new_instance.key
        self.get_instance_and_check()

    def test_get_instatnce(self):
        self.hash_key = '62d6c9f85b0ae677210102cb1b728f2b77e0885d'
        self.email = 's8901489@gmail.com'
        self.to_do_list = ['ToDo1', 'ToDo2', 'ToDo3']
        self.get_instance_and_check()


    def get_instance_and_check(self):
        todo_list = ToDoList.objects.get(email=self.email, key=self.hash_key)
        self.assertEqual(todo_list.get_list(), self.to_do_list)
        self.assertEqual(todo_list.key, self.hash_key)
        self.assertEqual(todo_list.email, self.email)