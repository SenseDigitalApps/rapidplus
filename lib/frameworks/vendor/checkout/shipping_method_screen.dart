import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiver/strings.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart'
    show
        AppModel,
        CartModel,
        ShippingMethod,
        Store,
        VendorShippingMethod,
        VendorShippingMethodModel;
import '../../../screens/checkout/widgets/delivery_calendar.dart';
import 'delivery_dropbox.dart';

class ShippingMethods extends StatefulWidget {
  final Function? onBack;
  final Function? onNext;

  const ShippingMethods({this.onBack, this.onNext});

  @override
  State<ShippingMethods> createState() => _ShippingMethodsState();
}

class _ShippingMethodsState extends State<ShippingMethods> {
  Map<String, int?> selectedMethods = {};

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final shippingMethodModel =
          Provider.of<VendorShippingMethodModel>(context, listen: false);
      final cartModel = Provider.of<CartModel>(context, listen: false);
      for (var selected in cartModel.selectedShippingMethods) {
        for (var element in shippingMethodModel.list) {
          if (selected.store.id == element.store!.id) {
            for (var i = 0; i < element.shippingMethods.length; i++) {
              if (element.shippingMethods[i].id ==
                  selected.shippingMethods[0].id) {
                setState(() {
                  selectedMethods[selected.store.id.toString()] = i;
                });
              }
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shippingMethodModel = Provider.of<VendorShippingMethodModel>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              S.of(context).shippingMethod,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ListenableProvider.value(
              value: shippingMethodModel,
              child: Consumer<VendorShippingMethodModel>(
                builder: (context, model, child) {
                  if (model.isLoading) {
                    return SizedBox(
                        height: 100, child: kLoadingWidget(context));
                  }

                  if (model.message != null) {
                    return SizedBox(
                      height: 100,
                      child: Center(
                          child: Text(model.message!,
                              style: const TextStyle(color: kErrorRed))),
                    );
                  }

                  if (model.list.isEmpty) {
                    return Center(
                      child: Image.asset(
                        'assets/images/empty_shipping.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (int i = 0; i < model.list.length; i++)
                        if (model.list[i].shippingMethods.isNotEmpty)
                          Column(
                            children: <Widget>[
                              if (model.list[i].store != null &&
                                  kVendorConfig['DisableVendorShipping'] !=
                                      true)
                                Container(
                                  decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).primaryColorLight),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.store,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        if (!isBlank(model.list[i].store!.name))
                                          Expanded(
                                            child: Text(
                                              model.list[i].store!.name!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  fontSize: 18),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              renderShippingMethods(model.list[i].store,
                                  model.list[i].shippingMethods),
                            ],
                          ),
                      const SizedBox(height: 20),
                      if (kAdvanceConfig.enableDeliveryDateOnCheckout &&
                          (shippingMethodModel.deliveryDates?.isNotEmpty ??
                              false)) ...[
                        Padding(
                          padding: EdgeInsets.only(
                              right: Tools.isRTL(context) ? 12.0 : 0.0,
                              left: !Tools.isRTL(context) ? 12.0 : 0.0),
                          child: Text(
                            S.of(context).deliveryDate,
                            style: Theme.of(context).textTheme.caption!,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DeliveryCalendar(
                            dates: shippingMethodModel.deliveryDates!),
                        const SizedBox(height: 20),
                      ],
                      if (kAdvanceConfig.enableDeliveryDateOnCheckout &&
                          (shippingMethodModel.deliveryDatesMV?.isNotEmpty ??
                              false)) ...[
                        Padding(
                          padding: EdgeInsets.only(
                              right: Tools.isRTL(context) ? 12.0 : 0.0,
                              left: !Tools.isRTL(context) ? 12.0 : 0.0),
                          child: Text(
                            S.of(context).deliveryDate,
                            style: Theme.of(context).textTheme.caption!,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (int i = 0; i < model.list.length; i++)
                          if (!isBlank(model.list[i].store!.name) &&
                              model.deliveryDatesMV![model.list[i].store!.id]!
                                  .isNotEmpty)
                            Row(
                              children: [
                                const SizedBox(
                                  width: 13.0,
                                ),
                                Text(
                                  model.list[i].store!.name!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                DeliveryDropbox(
                                  storeId: model.list[i].store!.id.toString(),
                                  dates: model.deliveryDatesMV![
                                      model.list[i].store!.id]!,
                                  onCallBack: (date) {
                                    final cartModel = Provider.of<CartModel>(
                                        context,
                                        listen: false);
                                    cartModel.setOrderDeliveryDateByStoreId(
                                        date,
                                        model.list[i].store!.id.toString());
                                  },
                                ),
                              ],
                            ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ButtonTheme(
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (selectedMethods.values.toList().isNotEmpty &&
                            selectedMethods.values.toList().length ==
                                shippingMethodModel.list.length) {
                          var list = <VendorShippingMethod>[];
                          for (var element in shippingMethodModel.list) {
                            list.add(VendorShippingMethod(element.store, [
                              element.shippingMethods[selectedMethods[
                                  element.store != null
                                      ? element.store!.id.toString()
                                      : '-1']!]
                            ]));
                          }
                          Provider.of<CartModel>(context, listen: false)
                              .setSelectedMethods(list);
                          widget.onNext!();
                        } else if (shippingMethodModel.list.isEmpty &&
                            (shippingMethodModel.message?.isEmpty ?? true)) {
                          widget.onNext!();
                        }
                      },
                      child: Text(S.of(context).continueToReview.toUpperCase()),
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  widget.onBack!();
                },
                child: Text(
                  S.of(context).goBackToAddress,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 15,
                      color: kGrey400),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget renderShippingMethods(
      Store? store, List<ShippingMethod> shippingMethods) {
    final currency =
        Provider.of<CartModel>(context, listen: false).currencyCode;
    final currencyRate =
        Provider.of<AppModel>(context, listen: false).currencyRate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < shippingMethods.length; i++)
            Column(
              children: <Widget>[
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    child: Row(
                      children: <Widget>[
                        Radio(
                          value: i,
                          groupValue: store != null &&
                                  selectedMethods[store.id.toString()] != null
                              ? selectedMethods[store.id.toString()]
                              : selectedMethods['-1'],
                          onChanged: (dynamic i) {
                            setState(() {
                              selectedMethods[store != null
                                  ? store.id.toString()
                                  : '-1'] = i;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(shippingMethods[i].title!,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary)),
                              const SizedBox(height: 5),
                              if (shippingMethods[i].cost! > 0.0 ||
                                  !isNotBlank(shippingMethods[i].classCost))
                                Text(
                                  PriceTools.getCurrencyFormatted(
                                      shippingMethods[i].cost, currencyRate,
                                      currency: currency)!,
                                  style: const TextStyle(
                                      fontSize: 14, color: kGrey400),
                                ),
                              if (shippingMethods[i].cost == 0.0 &&
                                  isNotBlank(shippingMethods[i].classCost))
                                Text(
                                  shippingMethods[i].classCost!,
                                  style: const TextStyle(
                                      fontSize: 14, color: kGrey400),
                                )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                i < shippingMethods.length - 1
                    ? const Divider(height: 1)
                    : Container()
              ],
            )
        ],
      ),
    );
  }
}
