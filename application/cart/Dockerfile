# FROM node:20-alpine AS build
# WORKDIR /app
# COPY *.json .
# RUN npm install
# COPY . .

# FROM node:20-alpine
# WORKDIR /app
# RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
# ENV REDIS_HOST=redis \
#     CATALOGUE_HOST=catalogue \
#     CATALOGUE_PORT=8080
# LABEL project="roboshop" \
#       author="krishna" \
#       component="cart"
# COPY --chown=roboshop:roboshop --from=build /app /app
# USER roboshop
# ENTRYPOINT ["node","server.js"]

FROM node:20-alpine AS build
WORKDIR /app
COPY *.json .
RUN npm install
COPY . .

FROM node:20-alpine
WORKDIR /app
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
# ENV REDIS_HOST=redis \
#     CATALOGUE_HOST=catalogue \
#     CATALOGUE_PORT=8080
LABEL project="roboshop" \
      author="krishna" \
      component="cart"
COPY --chown=roboshop:roboshop --from=build /app /app
USER roboshop
ENTRYPOINT ["node","server.js"]