import React, { Component } from 'react';
import { connect } from 'react-redux';
import Select from 'react-select';
import { fetchParams } from '../actions';
// import 'react-select/dist/rect-select.css';


class App extends Component {
  componentDidMount() {
    this.props.fetchParams();
  }

  render() {
    if (!this.props.params) {
      return  <div>Loading...</div>
    }

console.log(this.props.params);
console.log(this.props.params[0]);

    return (
      <div>React simple starter
        <Select
          name = 'listNV'
          options = {this.props.params.listNv}
        />
        <ul>
          <li>
            {this.props.params[0]}
          </li>
        </ul>
      </div>
    );
  }
}

function mapStatetoProps(state) {
  return { params: state.params };
}

export default connect(mapStatetoProps, { fetchParams })(App);
