FROM python:3

ENV PATH=/root/.local/bin:$PATH

RUN pip install pipx && \
    pipx ensurepath &&\
    pipx install mkdocs && \
    pipx runpip mkdocs install mkdocs-material
