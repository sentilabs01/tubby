FROM node:18-alpine
WORKDIR /app
COPY router.js ./
RUN npm init -y && npm install express axios
EXPOSE 8080
CMD ["node","router.js"] 