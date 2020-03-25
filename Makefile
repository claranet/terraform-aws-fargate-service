PHONY: all
all:
	isort --recursive *.py test/*.py
	black *.py test/*.py
	flake8 --ignore E501 *.py test/*.py
	terraform fmt -recursive
