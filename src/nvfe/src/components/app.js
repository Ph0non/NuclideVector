import React, { Component } from 'react';
import { connect } from 'react-redux';
import Select from 'react-select';
import { fetchParams } from '../actions';
// import 'react-select/dist/react-select.css';


class App extends Component {
  componentDidMount() {
    this.props.fetchParams();
  }

/////////////////
  state = {
    selectedOption: '',
  }
  handleChange = (selectedOption) => {
    this.setState({ selectedOption });
    console.log(`Selected: ${selectedOption.label}`);
  }
//////////////////

  render() {
    if (!this.props.params) {
      return  <div>Loading...</div>
    }

console.log(this.props.params);
// console.log(this.props.params[0]);

    const { selectedOption } = this.state;
    const value = selectedOption && selectedOption.value;

    return (
      <div>React simple starter
        <Select
          name = 'listNV'
          value={value}
          options={this.props.params.listNv}
        />
        <ul>
          <li>
            {this.props.params.listNv}
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
