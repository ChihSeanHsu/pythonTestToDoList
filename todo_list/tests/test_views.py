from django.test import TestCase
from django.urls import resolve

from todo_list.views import HomePage


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

