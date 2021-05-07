import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ModalWithNavigatorAndNestedNavigation extends StatelessWidget {
  const ModalWithNavigatorAndNestedNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext rootContext) {
    return Material(
        child: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context2) => Builder(
          builder: (context) => CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
                leading: Container(), middle: Text('Modal Page')),
            child: SafeArea(
              bottom: false,
              child: ListView(
                shrinkWrap: true,
                controller: ModalScrollController.of(context),
                children: ListTile.divideTiles(
                  context: context,
                  tiles: List.generate(
                      100,
                      (index) => ListTile(
                            title: Text('Item'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ModalWithNavigator2(title: "test3"),
                                ),
                              );
                            },
                          )),
                ).toList(),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class ModalWithNavigator2 extends StatelessWidget {
  const ModalWithNavigator2({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext rootContext) {
    return Material(
      child: SafeArea(
        bottom: false,
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(title),
          ),
          child: ListView(
            shrinkWrap: true,
            controller: ModalScrollController.of(rootContext),
            children: ListTile.divideTiles(
              context: rootContext,
              tiles: List.generate(
                  100,
                  (index) => ListTile(
                        title: Text('Item'),
                        onTap: () {
                          Navigator.of(rootContext)
                              .push(MaterialPageRoute(builder: (context3) {
                            return ModalWithNavigator2(title: "Page 3");
                          }));
                        },
                      )),
            ).toList(),
          ),
        ),
      ),
    );
  }
}
