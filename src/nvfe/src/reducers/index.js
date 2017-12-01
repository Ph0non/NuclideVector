import { combineReducers } from 'redux';
import ParamsReducer from './reducer_params';

const rootReducer = combineReducers({
  params: ParamsReducer
});

export default rootReducer;
