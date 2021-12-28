FROM python:3

RUN pip install pipx && \
    pipx ensurepath &&\
    pipx install mkdocs && \
    pipx runpip mkdocs install mkdocs-material
