from django.test import TestCase
from selenium import webdriver
from selenium.webdriver.common.keys import Keys 
import time 



class FunctionalTest(TestCase):

    # do something before test start
    def setUp(self):
        self.browser = webdriver.Firefox()

    # do something after test complete
    def tearDown(self):
        self.browser.quit()

    # our test function
    def test_to_do_list_ok(self):
        self.browser.get('http://localhost:8000')
        self.assertIn('To-Do', self.browser.title)
        
        header = self.browser.find_element_by_tag_name('h1')
        self.assertEqual('To-Do List', header.text)
        
        new_items = ['first item', 'second item']

        self.input_new_item(new_items[0])
        self.check_to_do_list()

        self.input_new_item(new_items[1])
        self.check_to_do_list()
    
    def input_new_item(self, item):
        input_field = self.browser.find_element_by_id('new_item')
        self.assertEqual('Input New Item', input_field.get_attribute('placeholder'))
        input_field.send_keys(item)
        input_field.send_keys(Keys.ENTER)
        time.sleep(1)

    def check_to_do_list(self):
        list_div = self.browser.find_element_by_id('to-do-list')
        to_do_list = list_div.find_elements_by_tag_name('li')
        self.assertTrue(all(to_do.text == new_items[index] for index, to_do in enumerate(to_do_list)))


