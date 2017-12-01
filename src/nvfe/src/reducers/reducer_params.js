import _ from 'lodash';
import { FETCH_PARAMS } from '../actions';

export default function(state = {}, action) {
  switch (action.type) {
  case FETCH_PARAMS:
    // console.log( [ action.payload.data, ...state ]);
    return [ action.payload.data.data.listNv, ...state ];
  default:
    return state;
  }
}
