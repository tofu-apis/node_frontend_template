import React, { Component } from "react";
import { gql } from "@apollo/client";
import { query } from "../../api/graphQLClient";
import { getEnv } from "../../env/main";

// Move query into a separate file
const serverStatusQuery = gql`
  query getServerStatus {
    serverStatus {
      isServerAvailable
      mongoDBConnectionStatus
    }
  }
`;

interface ServerStatus {
  isServerAvailable: boolean;
  mongoDBConnectionStatus: string;
}

interface QueryResponse {
  serverStatus: ServerStatus;
}

class ServerStatus extends Component<
  {},
  { isServerAvailable?: boolean; mongoDBConnectionStatus?: string }
> {
  constructor(props: {}) {
    super(props);
    this.state = {};
  }

  async componentDidMount() {
    let queryResult;
    try {
      queryResult = await query<QueryResponse>(serverStatusQuery);
    } catch (err) {
      this.setState({
        isServerAvailable: false,
      });
      return;
    }

    const { loading, data } = queryResult;

    if (!loading) {
      this.setState({
        isServerAvailable: data!.serverStatus.isServerAvailable,
        mongoDBConnectionStatus: data!.serverStatus.mongoDBConnectionStatus,
      });
    }
  }

  public render() {
    const isServerAvailable = this.state.isServerAvailable;
    const mongoDBConnectionStatus = this.state.mongoDBConnectionStatus;

    let serverStatusString;

    if (isServerAvailable === undefined || isServerAvailable === null) {
      serverStatusString = "Connecting...";
    } else if (!isServerAvailable) {
      serverStatusString = "UNAVAILABLE";
    } else {
      // The case where server is available
      serverStatusString = "AVAILABLE";
    }

    const mongoDBConnectionStatusString =
      isServerAvailable === undefined || isServerAvailable === null
        ? "TO_BE_DETERMINED"
        : mongoDBConnectionStatus;

    return (
      <div>
        Environment: {getEnv()}
        <br />
        API Server Status: {serverStatusString}
        <br />
        MongoDB Connection Status: {mongoDBConnectionStatusString}
        <br />
        Frontend App Version: {process.env.REACT_APP_VERSION}
      </div>
    );
  }
}

export default ServerStatus;
