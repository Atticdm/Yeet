# Use an official Node.js runtime as a parent image
FROM node:18-alpine

# Set the working directory in the container
WORKDIR /usr/src/app

# Install yt-dlp and dependencies
RUN apk add --no-cache python3 py3-pip ffmpeg && \
    pip install yt-dlp

# Copy package.json and package-lock.json from Server directory
COPY Server/package*.json ./

# Install app dependencies
RUN npm install --production

# Copy app source code from Server directory
COPY Server/ .

# Expose the port the app runs on
EXPOSE 3000

# Define the command to run the app
CMD ["npm", "start"]
