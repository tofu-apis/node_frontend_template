# To run this image execute the following commands:
# docker build --tag aptitude-backend:latest .
# docker run --detach --publish 3000:3000 aptitude-backend:latest

# Set the base image to jadesym/node-ubuntu-docker-base
# https://hub.docker.com/repository/docker/jadesym/node-ubuntu-docker-base
# Tag 0.0.2
FROM tofuapis/node-yarn-ubuntu-docker-base@sha256:8d6f3ca18844f135ffbde572f3c91f7c6231fc8d32ce3b5b55e1b7da177685d0 as base

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
# Confirm Node Installation
RUN node -v
RUN yarn --version

# Adding non-interactive for debian front-end to hide dialog questions during build.
# Args only live during the build so they do not persist to the final image.
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get install -qq -y \
        less \
    && apt-get -qq -y autoclean

#----------------------------------------------------------------------
# User & Directory Setup
#----------------------------------------------------------------------
RUN mkdir -p $APP_DIR

RUN useradd -ms /bin/bash $USER_NAME
RUN chown -R $USER_NAME:$USER_NAME $DATA_DIR

USER $USER_NAME

WORKDIR $APP_DIR

#----------------------------------------------------------------------
# Loading & Running the Repository Code
#----------------------------------------------------------------------
# Copy configuration and dependency files
COPY --chown=$USER_NAME:$USER_NAME \
  # Copy NPM RC file for npm configurations
  .npmrc \
  # Copy Yarn RC YAML file for yarn configurations
  .yarnrc.yml \
  # Copy dependencies definition files [package(-lock).json] as source of truth for dependencies
  yarn.lock \
  package.json \
  # Typescript configuration
  tsconfig.json \
  # To destination directory
  $APP_DIR

# Downloading wait-for for deploying based upon dependency services
RUN wget https://raw.githubusercontent.com/eficode/wait-for/master/wait-for
RUN chmod u+rwx $APP_DIR/wait-for

# Install dependencies from package lock (clean install)
RUN yarn install --frozen-lockfile

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

RUN yarn run build:$NODE_ENV

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
# CMD ["yarn", "run", "lint"]

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
# CMD ["yarn", "run", "test:e2e"]

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

# Copying only the test and base environment files.
COPY \
  .env \
  .env.test* \
  jestconfig.json \
  # To destination directory
  $APP_DIR

CMD ["yarn", "run", "test:unit"]

#----------------------------------------------------------------------
# Use multi-stage builds to have the test image
#----------------------------------------------------------------------
FROM base as app

COPY \
  --from=builder \
  $APP_DIR/build $APP_DIR/build

# Start the server
CMD ["npx", "serve", "--single", "--no-clipboard", "./build"]
