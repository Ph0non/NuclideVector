import React, { Component } from 'react';
import ReactDOM from 'react-dom';
import Select from 'react-select';
import axios from 'axios';
import _ from 'lodash';

class Data extends Component {
  constructor(props) {
   super(props);

   this.state = {
     array: []
   };

   this.renderNVList = this.renderNVList.bind(this);
 }

 componentDidMount(){
   axios
     .get('http://localhost:8888/__getNvList__/')
     .then(({ data })=> {
       console.log(data);
       this.setState(
         { array: data.data }
       );
     })
     .catch((err)=> {})
 }

 render() {
   console.log(this.state.array);
   return(
     <div>
       <h3>Recipes</h3>
       <Select
         name = 'listNV'
         value={this.state.array.value}
         options={this.state.array.value}
       />
       <ul className="list-group">
          {this.renderNVList()}
       </ul>
     </div>
   );
 }

 renderNVList() {
   console.log(this.state.array);
   return _.map(this.state.array, NVList => {
     return (
       <li className="list-group-item" key={NVList.value}>
           {NVList.value}
       </li>
     );
   });
 }
}

export default Data;
