FROM node:20-alpine AS build
WORKDIR /app
COPY *.json .
COPY *.js .
RUN npm install

FROM node:20-alpine
WORKDIR /app
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop 
# ENV MONGO=true \
#     REDIS_URL='redis://redis:6379' \
#     MONGO_URL="mongodb://mongodb:27017/users" 
LABEL project="roboshop" \
      author="krishna" \
      component="user"
COPY --chown=roboshop:roboshop --from=build /app /app
USER roboshop
ENTRYPOINT ["node","server.js"]
