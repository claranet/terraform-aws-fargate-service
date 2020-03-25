from unittest.mock import ANY
from urllib.request import urlopen

import pytest
from pretf import test


class state:
    pass


class TestModule(test.SimpleTest):
    def test_init(self):
        self.pretf.init()

    def test_apply(self):
        """
        Create the Fargate service using the default image.

        """

        outputs = self.pretf.apply()
        assert outputs == {"url": ANY}
        state.url = outputs["url"]

    def test_default_request(self):
        """
        Test that the URL works.

        """

        with urlopen(state.url) as response:
            assert response.status == 200
            html = response.read().decode()
            assert "Your web server is working" in html
            assert "Custom image" not in html

    @pytest.mark.skip("not implemented")
    def test_build_docker_image(self):
        raise NotImplementedError

    @pytest.mark.skip("not implemented")
    def test_push_to_ecr(self):
        raise NotImplementedError

    @pytest.mark.skip("not implemented")
    def test_invoke_lambda(self):
        raise NotImplementedError

    @pytest.mark.skip("not implemented")
    def test_custom_request(self):
        """
        Test that the URL works.

        """

        with urlopen(state.url) as response:
            assert response.status == 200
            html = response.read().decode()
            assert "Your web server is working" not in html
            assert "Custom image" in html

    @pytest.mark.skip("not implemented")
    @test.always
    def test_destroy(self):
        self.pretf.destroy()
