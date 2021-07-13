FROM node:alpine
WORKDIR /usr/app
COPY ./visits/package.json ./
RUN npm install
COPY ./visits/ ./
CMD [ "npm","start"]