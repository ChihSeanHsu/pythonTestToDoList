from unittest import mock # 1.import mock

from django.test import TestCase
from django.urls import resolve

from todo_list.views import HomePage
from todo_list.models import ToDoList


class TestHomePageView(TestCase):

    def test_resolve_to_home_page(self):
        # resolve root path
        found = resolve('/')

        # check function name is equal
        self.assertEqual(found.func.__name__, HomePage.as_view().__name__)

    def test_get_home_page(self):
        # get url localhost:8000/
        response = self.client.get('/')

        # check which template is used
        self.assertTemplateUsed(response, 'home.html')

        # check response status is equal to 200
        self.assertEqual(response.status_code, 200)

    def test_post_new_to_do_item(self):
        response = self.client.post('/', { 'new_item': 'first' })
        self.assertEqual(response.status_code, 200)
        self.assertIn('first', response.content.decode())

    def test_post_two_new_to_do(self):
        to_do_list = ['first', 'second']

        for index, item in enumerate(to_do_list):
            response = self.client.post('/', { 'new_item': item })
            self.assertEqual(response.status_code, 200)
            self.assertIn(item, response.content.decode())

        self.assertIn(to_do_list[0], response.content.decode())

    @mock.patch('todo_list.views.send_mail') # 2.use decorator to tell mock which fucntion
    def test_save_todo_list(self, m_send_mail): # 3.pass mock instance to ut
        email = 'test@gmail.com'
        to_do_list = ['first', 'second']

        # create data in session
        for index, item in enumerate(to_do_list):
            response = self.client.post('/', { 'new_item': item })
        
        response = self.client.post('/save', {
            'email': email,
        })
        self.assertEqual(response.status_code, 200)
        key = response.content.decode()
        todo_list_instance = ToDoList.objects.get(key=key, email=email)

        self.assertEqual(todo_list_instance.get_list(), to_do_list)
        # 4.assert if send_mail did not call
        m_send_mail.assert_called_once()
        # 5.assert if args were not email and to_do_list
        m_send_mail.assert_called_with(
            'Your Todo list',
            f'Click here to get your list http://testserver:80/?key={key}',
            'TODO_LIST', 
            [email]
        )
