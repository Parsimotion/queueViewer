FROM node:carbon-alpine

WORKDIR /usr/src/app
COPY package.json .
COPY package-lock.json .
COPY ./src ./src
RUN npm install --production

EXPOSE 9000
CMD [ "npm", "start" ]
