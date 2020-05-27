import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttercredittransferapp/screens/models/ModelForTransaction.dart';
import 'package:fluttercredittransferapp/services/Database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_dialog/material_dialog.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';

class TransferMaterialDialog extends StatefulWidget {

  String receiverUid;

  TransferMaterialDialog({ this.receiverUid });

  @override
  _TransferMaterialDialogState createState() => _TransferMaterialDialogState();
}

class _TransferMaterialDialogState extends State<TransferMaterialDialog> {


  final _formKey = GlobalKey<FormState>();
  ProgressDialog progressDialog;
  String senderUid;
  String senderCredit;
  String senderName;
  String receiverUid;
  String receiverCredit;
  String receiverName;
  String transactionCredit = '';
  String transactionDateTime;

  @override
  Widget build(BuildContext context) {

    final senderUser = Provider.of<DocumentSnapshot>(context);

    if(senderUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    progressDialog = ProgressDialog(
        context,
        type: ProgressDialogType.Download,
        isDismissible: true
    );
    progressDialog.style(
      message: 'Transferring credit...',
      borderRadius: 10.0,
      backgroundColor: Colors.white,
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      progress: 0.0,
      maxProgress: 100.0,
    );

    return MaterialDialog(
      borderRadius: 8.0,
      children: <Widget>[
        Center(
            child: Text(
              'You have ${senderUser.data['credit']} credits',
              style: TextStyle(
                fontSize: 15.0,
              ),
            ),
        ),
        SizedBox(
          height: 20.0,
        ),
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() => transactionCredit = value);
                },
                validator: (value) {
                  if(value.isEmpty) {
                    return 'Enter credit to be transfered';
                  } else if(int.parse(value) > int.parse(senderUser.data['credit'])) {
                    return "You don't have enough credit to transfer";
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  hintText: '150',
                  labelText: 'Credit',
                  labelStyle: TextStyle(
                    color: Colors.deepPurple[900],
                  ),
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: Colors.deepPurple[900],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:  BorderSide(
                      color: Colors.deepPurple[900],
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              RaisedButton(
                onPressed: () async {
                  if(_formKey.currentState.validate()) {
                    await progressDialog.show();

                    senderUid = senderUser.data['uid'];
                    senderCredit = senderUser.data['credit'];
                    senderName = senderUser.data['name'];
                    receiverUid = widget.receiverUid;

                    List<String> receiverUser = await DatabaseService(uid: widget.receiverUid).getUserNameCredit();
                    receiverName = receiverUser[0];
                    receiverCredit = receiverUser[1];

                    // computing credits of sender and receiver
                    senderCredit = (int.parse(senderCredit) - int.parse(transactionCredit)).toString();
                    receiverCredit = (int.parse(receiverCredit) + int.parse(transactionCredit)).toString();

                    // date and time of transaction
                    transactionDateTime = DateFormat.yMd().add_jm().format(DateTime.now()).toString();

                    // creating two transaction objects
                    ModelForTransaction toReceiver = ModelForTransaction(uid: receiverUid, type: 'to', name: receiverName,
                                                                              credit: transactionCredit, dateTime: transactionDateTime);

                    ModelForTransaction fromSender = ModelForTransaction(uid: senderUid, type: 'from', name: senderName,
                                                                          credit: transactionCredit, dateTime: transactionDateTime);



                    // updating sender details in database
                    await DatabaseService().updateCreditDetails(senderUid, senderCredit).then((value) async {
                      // updating receiver details in database
                      await DatabaseService().updateCreditDetails(receiverUid, receiverCredit).then((value) async {
                        // adding transaction detail of sender in database
                        await DatabaseService(uid: senderUid).insertTransactionDetails(toReceiver).then((value) async {
                          // adding transaction detail of receiver in database
                          await DatabaseService(uid: receiverUid).insertTransactionDetails(fromSender).then((value) async {
                            await progressDialog.hide();
                            Fluttertoast.showToast(msg: "Creditd transferred successfully", toastLength: Toast.LENGTH_LONG);
                          }).catchError((error) {
                            Fluttertoast.showToast(msg: "error: "+error, toastLength: Toast.LENGTH_LONG);
                          });
                        }).catchError((error) {
                          Fluttertoast.showToast(msg: "error: "+error, toastLength: Toast.LENGTH_LONG);
                        });
                      }).catchError((error) {
                        Fluttertoast.showToast(msg: "error: "+error, toastLength: Toast.LENGTH_LONG);
                      });
                    }).catchError((error) {
                      Fluttertoast.showToast(msg: "error: "+error, toastLength: Toast.LENGTH_LONG);
                    });

                    Navigator.pop(context);

                  }
                },
                color: Colors.deepPurple[900],
                child: Text(
                  'Transfer Credit',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
