# To run this image execute the following commands:
# docker build --tag aptitude-backend:latest .
# docker run --detach --publish 3000:3000 aptitude-backend:latest

# Set the base image to jadesym/node-ubuntu-docker-base
# https://hub.docker.com/repository/docker/jadesym/node-ubuntu-docker-base
FROM jadesym/node-ubuntu-docker-base:latest as base

#----------------------------------------------------------------------
# Build arguments and environment variables
#----------------------------------------------------------------------
ARG USER_NAME=node
ARG DATA_DIR=/data/
ARG NODE_ENV
ENV APP_DIR=$DATA_DIR/app/
ENV NODE_ENV $NODE_ENV

#----------------------------------------------------------------------
# Dependencies Installation
#----------------------------------------------------------------------
# Confirm Node Installation (use for debugging)
# RUN node -v && npm -v

# Adding non-interactive for debian front-end to hide dialog questions during build.
# Args only live during the build so they do not persist to the final image.
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get install -qq -y \
        less \
    && apt-get -qq -y autoclean

#----------------------------------------------------------------------
# User & Directory Setup
#----------------------------------------------------------------------
RUN mkdir -p $APP_DIR \
    && useradd -ms /bin/bash $USER_NAME \
    && chown -R $USER_NAME:$USER_NAME $DATA_DIR

USER $USER_NAME

WORKDIR $APP_DIR

#----------------------------------------------------------------------
# Loading & Running the Repository Code
#----------------------------------------------------------------------
# Copy configuration and dependency files
COPY --chown=$USER_NAME:$USER_NAME \
  # Copy NPM RC file for npm configurations
  .npmrc \
  # Copy dependencies definition files [package(-lock).json] as source of truth for dependencies
  package-lock.json \
  package.json \
  # Typescript configuration
  tsconfig.json \
  # To destination directory
  $APP_DIR

# Install dependencies from package lock (clean install)
RUN npm ci

# Copy source code contents. Directories are treated differently.
# Copying with multiple source files will copy the contents of the file
# instead of the directory, which is why this COPY command is separate.
COPY --chown=$USER_NAME:$USER_NAME \
  src $APP_DIR/src
COPY --chown=$USER_NAME:$USER_NAME \
  public $APP_DIR/public
#----------------------------------------------------------------------
# Use multi-stage builds to build the environment
#----------------------------------------------------------------------
FROM base as builder

COPY \
  .env* \
  $APP_DIR

RUN echo $NODE_ENV
RUN echo build:$NODE_ENV
RUN npm run build:$NODE_ENV

#----------------------------------------------------------------------
# Use multi-stage builds to run the linter
#----------------------------------------------------------------------
# FROM base as linter
#
# COPY --chown=$USER_NAME:$USER_NAME \
#   .eslintrc.js \
#   .prettierrc \
#   $APP_DIR
#
# CMD ["npm", "run", "lint"]

#----------------------------------------------------------------------
# Use multi-stage builds to have the e2e test image
#----------------------------------------------------------------------
# FROM base as test-e2e
#
# # Copying necessary e2e test files
# COPY --chown=$USER_NAME:$USER_NAME \
#   jestconfig.json \
#   # To destination directory
#   $APP_DIR
# COPY test/e2e $APP_DIR/test/e2e
#
# CMD ["npm", "run", "test:e2e"]

#----------------------------------------------------------------------
# Use multi-stage builds to have the unit test image
#----------------------------------------------------------------------
FROM base as test-unit

# Copying necessary unit test files
COPY \
  jestconfig.json \
  # To destination directory
  $APP_DIR

# Copying source code since it contains src and test files
COPY \
  --from=builder \
  $APP_DIR/src $APP_DIR/src

# Attempting a temporary hack to see if this fixes the COPY failure issue
# Remove this hack once the below issue with multi-stage build Docker is resolved:
# https://github.com/moby/moby/issues/37965
RUN true

# Copying only the test and base environment files.
COPY \
  .env $APP_DIR
COPY \
  .env.test* $APP_DIR

CMD ["npm", "run", "test:unit"]

#----------------------------------------------------------------------
# Use multi-stage builds to have the test image
#----------------------------------------------------------------------
FROM base as app

COPY \
  --from=builder \
  $APP_DIR/build $APP_DIR/build

# Start the server
CMD ["npx", "serve", "--single", "--no-clipboard", "./build"]
