import 'package:connectivity/connectivity.dart';
import 'package:drivxpro/components/Button.dart';
import 'package:drivxpro/components/FormError.dart';
import 'package:drivxpro/components/Icon.dart';
import 'package:drivxpro/components/ProgressDialog.dart';
import 'package:drivxpro/screens/forgotPasswordScreen.dart';
import 'package:drivxpro/screens/mainScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import "package:drivxpro/constants.dart";

class SignInForm extends StatefulWidget {
  @override
  _SignInFormState createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  String email;
  String password;
  bool remember = false;
  final _formKey = GlobalKey<FormState>();
  final List<String> errors = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void addError({String error}) {
    if (!errors.contains(error))
      setState(() {
        errors.add(error);
      });
  }

  void removeError({String error}) {
    if (errors.contains(error))
      setState(() {
        errors.remove(error);
      });
  }

  void login() async{

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(status: "Logging you ...")
    );

    final User user = (
        await _auth.signInWithEmailAndPassword(email: email, password: password).catchError((err){
          Navigator.pop(context);
          addError(error:"Email or password doesn't match");
        })).user;

      if(user != null){
        DatabaseReference userRef = FirebaseDatabase.instance.reference().child('drivers/${user.uid}');
        userRef.once().then((DataSnapshot snapshot) => {
          if(snapshot.value != null){
            Navigator.pushNamedAndRemoveUntil(context, MainScreen.routeName,(route) => false),
          }
        });
      }

  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
      child: Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            onSaved: (newValue) => email = newValue,
            onChanged: (value) {
              if (value.isNotEmpty) {
                removeError(error: emailNullError);
              } else if (emailValidatorRegExp.hasMatch(value)) {
                removeError(error: invalidEmailError);
              }
              return null;
            },
            validator: (value) {
              if (value.isEmpty) {
                addError(error: emailNullError);
                return "";
              } else if (!emailValidatorRegExp.hasMatch(value)) {
                addError(error: invalidEmailError);
                return "";
              }
              return null;
            },
            decoration: InputDecoration(
                labelText: "Email",
                hintText: "Enter your email",
              floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon:CustomIcon(svgIcon:"assets/icons/mail.svg", height: 30)
            ),

          ),
          SizedBox(height: 20),
          TextFormField(
            obscureText: true,
            onSaved: (newValue) => password = newValue,
            onChanged: (value) {
              if (value.isNotEmpty) {
                removeError(error: passNullError);
              } else if (value.length >= 8) {
                removeError(error: shortPassError);
              }
              return null;
            },
            validator: (value) {
              if (value.isEmpty) {
                addError(error: passNullError);
                return "";
              }
              return null;
            },
            decoration: InputDecoration(
                labelText: "Password",
                hintText: "Enter your password",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon:CustomIcon(svgIcon:"assets/icons/lock.svg",height:30)
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: remember,
                activeColor: Color(0xfff00000),
                onChanged: (value) {
                  setState(() {
                    remember = value;
                  });
                },
              ),
              Text("Remember me"),
              Spacer(),
              GestureDetector(
               onTap:
                    ()=> Navigator.pushNamed(
                    context, ForgotPasswordScreen.routeName)
               ,
                  child: Text("Forgot Password",
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              )
            ],
          ),
          SizedBox(height: 20),
          FormError(errors: errors),
          SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: Button(text:"Sign in",
              press: () async {
                var connectResult = Connectivity().checkConnectivity();
                if(connectResult != ConnectivityResult.mobile && connectResult != ConnectivityResult.wifi) {
                  print("No internet Connection");
                }
            if (_formKey.currentState.validate()){
              _formKey.currentState.save();
              login();
            }
          })
          )
        ]
      )
    );
  }
}
