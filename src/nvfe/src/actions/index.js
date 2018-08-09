import axios from 'axios';

export const FETCH_PARAMS = 'fetch_params';

const ROOT_URL = 'http://localhost:8888';

export function fetchParams() {
  const request = axios.get(`${ROOT_URL}/getParameters`);

  return {
    type: FETCH_PARAMS,
    payload: request
  };
}
