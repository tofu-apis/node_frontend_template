export function getAPIBaseUrl(): string {
  const uriScheme = process.env.REACT_APP_BACKEND_URI_SCHEME;
  const hostName = process.env.REACT_APP_BACKEND_APP_HOST;
  const port = process.env.REACT_APP_BACKEND_APP_PORT;

  const portNumber = Number(port);

  if (isNaN(portNumber) || !Number.isInteger(portNumber)) {
    throw new Error(
      `Port string ${port} must be a valid integer. Check the port configuration. Current env is ${process.env.NODE_ENV}.`
    );
  }

  return `${uriScheme}://${hostName}:${portNumber.toString()}`;
}

export function getEnv(): string {
  if (process.env.REACT_APP_REAL_ENV === undefined) {
    throw new Error("NODE_ENV environment variable must be non-empty.");
  }
  return process.env.REACT_APP_REAL_ENV;
}
