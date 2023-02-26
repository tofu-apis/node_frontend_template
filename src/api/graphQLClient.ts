import {
  ApolloClient,
  DocumentNode,
  InMemoryCache,
  OperationVariables,
} from "@apollo/client";
import { onError } from "@apollo/client/link/error";
import { BatchHttpLink } from "@apollo/client/link/batch-http";
import { from } from "@apollo/client";

import { getAPIBaseUrl } from "../env/main";

const errorLink = onError(
  ({ graphQLErrors, networkError, operation, forward }) => {
    if (graphQLErrors)
      graphQLErrors.map(({ message, locations, path }) =>
        console.log(
          `[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`
        )
      );

    if (networkError)
      console.log(
        `[Network error]: ${networkError} for query with name: ${operation.operationName}`
      );

    return forward(operation);
  }
);

const client = new ApolloClient({
  link: from([errorLink, new BatchHttpLink({ uri: getAPIBaseUrl() })]),
  uri: getAPIBaseUrl(),
  cache: new InMemoryCache(),
});

export async function query<T>(
  query: DocumentNode,
  variables?: OperationVariables
) {
  return await client.query<T>({
    query,
    variables,
    errorPolicy: "all",
  });
}

export default client;
