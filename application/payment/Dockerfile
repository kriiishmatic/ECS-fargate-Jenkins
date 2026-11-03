# FROM python:3.9 AS build
# WORKDIR /app
# COPY requirements.txt . \
#      *.py . \
#      payment.ini .
# RUN pip3 install -r requirements.txt

# FROM python:3.9
# WORKDIR /app
# RUN addgroup roboshop && useradd -g roboshop roboshop && \
#     chown -R roboshop:roboshop /app
# ENV CART_HOST=cart \
#     CART_PORT=8080 \
#     USER_HOST=user \
#     USER_PORT=8080 \
#     AMQP_HOST=rabbitmq \
#     AMQP_USER=roboshop \
#     AMQP_PASS=roboshop123
# LABEL project="roboshop" \
#       author="krishna" \
#       component="payment"
# EXPOSE 8080
# COPY --chown=roboshop:roboshop --from=build /app /app

# FROM python:3.9
# EXPOSE 8080
# WORKDIR /app
# COPY payment.ini .
# COPY *.py .
# COPY requirements.txt .
# RUN pip3 install -r requirements.txt
# ENV CART_HOST="cart" \
#     CART_PORT="8080" \
#     USER_HOST="user" \
#     USER_PORT="8080" \
#     AMQP_HOST="rabbitmq" \
#     AMQP_USER="roboshop" \
#     AMQP_PASS="roboshop123"
# LABEL project="roboshop" \
#       author="krishna" \
#       component="payment"
# RUN groupadd roboshop && \
#     useradd -g roboshop roboshop && \
#     chown -R roboshop:roboshop /app
# USER roboshop
# CMD ["uwsgi","--ini","payment.ini"]

FROM python:3.9-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


FROM python:3.9-slim

WORKDIR /app

COPY --from=builder /install /usr/local

RUN groupadd -r roboshop && useradd -r -g roboshop roboshop

# ENV CART_HOST="cart" \
#     CART_PORT="8080" \
#     USER_HOST="user" \
#     USER_PORT="8080" \
#     AMQP_HOST="rabbitmq" \
#     AMQP_USER="roboshop" \
#     AMQP_PASS="roboshop123"

LABEL project="roboshop" \
      author="krishna" \
      component="payment"

COPY --chown=roboshop:roboshop payment.ini .
COPY --chown=roboshop:roboshop *.py ./

USER roboshop

EXPOSE 8080

CMD ["uwsgi", "--ini", "payment.ini"]