FROM node:alpine as builder
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
# /app/build <-- all the stuff that we need (video number 87)
RUN npm run build

FROM nginx
COPY --from=builder /app/build /usr/share/nginx/html