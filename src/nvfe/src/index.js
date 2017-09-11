import React from 'react';
import ReactDOM from 'react-dom';
// import 'bootstrap/dist/css/bootstrap.css';
// import './index.css';

import Form from "react-jsonschema-form";

// const schema = {
//   "title": "A registration form",
//   "description": "A simple form example.",
//   "type": "object",
//   "required": [
//     "firstName",
//     "lastName"
//   ],
//   "properties": {
//     "firstName": {
//       "type": "string",
//       "title": "First name"
//     },
//     "lastName": {
//       "type": "string",
//       "title": "Last name"
//     },
//     "age": {
//       "type": "integer",
//       "title": "Age"
//     },
//     "bio": {
//       "type": "string",
//       "title": "Bio"
//     },
//     "password": {
//       "type": "string",
//       "title": "Password",
//       "minLength": 3
//     },
//     "telephone": {
//       "type": "string",
//       "title": "Telephone",
//       "minLength": 10
//     }
//   }
// }
//
// const uiSchema = {
//   "firstName": {
//     "ui:autofocus": true,
//     "ui:emptyValue": ""
//   },
//   "age": {
//     "ui:widget": "updown",
//     "ui:title": "Age of person",
//     "ui:description": "(earthian year)"
//   },
//   "bio": {
//     "ui:widget": "textarea"
//   },
//   "password": {
//     "ui:widget": "password",
//     "ui:help": "Hint: Make it strong!"
//   },
//   "date": {
//     "ui:widget": "alt-datetime"
//   },
//   "telephone": {
//     "ui:options": {
//       "inputType": "tel"
//     }
//   }
// }
//
// function Name(props) {
//   return <h1>Hallo, {props.name}!</h1>;
// }
//
// const hallo = <Name name=localhost:8888/testfn1/4/5?narg1=6&narg2=8 />;
//
// const log = (type) => console.log.bind(console, type);
//
//
// // const form =   (<Form schema={schema}
// //         uiSchema={uiSchema}
// //         onChange={log("changed")}
// //         onSubmit={log("submitted")}
// //         onError={log("errors")}
// //         />);
//
// ReactDOM.render((
//   hallo
// ), document.getElementById("root"));



// class ItemLister extends React.Component {
// 	constructor() {
//   	super();
//  		 this.state={items:[]};
//   }
//   componentDidMount(){
//   	fetch(`http://jsonplaceholder.typicode.com/posts`)
//  		.then(result=>result.json())
//     .then(items=>this.setState({items}))
//   }
//   render() {
//   	return(
//     	<ul>
//           {this.state.items.length ?
//           	this.state.items.map(item=><li key={item.id}>{item.body}</li>)
//             : <li>Loading...</li>
//           }
//       </ul>
//    )
//   }
// }

// ReactDOM.render(
//   <ItemLister />,
//   document.getElementById("root")
// );


// fetch('http://jsonplaceholder.typicode.com/posts/1').then((unresolvedResponse) => { return unresolvedResponse.json(); }).then((json) => { console.log(json); });
            // { this.state.items.map(item=> {return <div>{item.body}</div>}) }

class ItemLister extends React.Component {
    constructor() {
        super();
        this.state = { items: [] };
    }

    componentDidMount() {
      fetch(`http://localhost:8888/testfn2/10/5?narg1=6&narg2=8`)
      // fetch(`http://jsonplaceholder.typicode.com/posts/1`)
          .then(result=>result.json())
          .then(items=>this.setState({items}));
        }

    render() {
      return(
        <div>
          <div>Item:</div>
              {this.state.items.data}
          </div>
      );
    }
}

ReactDOM.render(
  <ItemLister />,
  document.getElementById('root')
);
