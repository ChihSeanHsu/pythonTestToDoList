import unittest
from unittest.mock import Mock

# Mock requests to control its behavior
requests = Mock()

def get_something():
    r = requests.get('http://some.domain/api/get_something')
    if r.status_code == 200:
        return r.json()
    return None

class TestMock(unittest.TestCase):

    def fake_response(self, url):
        # Create a new Mock to imitate a Response
        print(f'We are getting something from {url}')
        response_mock = Mock()
        response_mock.status_code = 200
        response_mock.json.return_value = {
            'item1': 'test',
            'item2': 'yeee'
        }
        return response_mock

    def test_get_something(self):
        # Set the side effect of .get()
        requests.get.side_effect = self.fake_response
        
        # Now retry, expecting a successful response
        assert get_something()['item1'] == 'test'


if __name__ == '__main__':
    unittest.main()