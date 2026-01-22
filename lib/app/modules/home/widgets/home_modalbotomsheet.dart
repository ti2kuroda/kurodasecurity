import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/retrato_model.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../controllers/home_controller.dart';
import 'textformfield.dart';

class HomeModalBotomSheet extends GetWidget<HomeController> {
  const HomeModalBotomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    var maskFormatter = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );

    return Form(
      key: controller.formKey,
      child: Padding(
        padding: EdgeInsets.only(
          top: height * 0.04,
          left: width * 0.08,
          right: width * 0.08,
          bottom: height * 0.02,
        ),
        child: SingleChildScrollView(
          child: Column(
            spacing: 15,
            children: [
              Text(
                "Formulário do Retrato",
                style: TextStyle(fontSize: width / 15, color: Colors.white),
              ),
              HomeTextFormField(
                hintText: "Titulo do Retrato.",
                iconData: Icons.library_books_outlined,
                controller: controller.titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título.';
                  }
                  return null;
                },
                textInputType: TextInputType.text,
              ),

              HomeTextFormField(
                hintText: "Data do Ocorrido.",
                iconData: Icons.calendar_month,
                textFormatter: maskFormatter,
                controller: controller.dateController,
                textInputType: TextInputType.numberWithOptions(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma data.';
                  }
                  return null;
                },
              ),
              Obx(() {
                return Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField(
                      initialValue: controller.selectedDropDownItem.value,

                      borderRadius: BorderRadius.circular(20),
                      dropdownColor: Colors.white,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: width / 25,
                      ),
                      decoration: InputDecoration(
                        filled: true,

                        fillColor: Colors.white,
                        labelText: 'Selecione o tipo de Ocorrido.',
                        labelStyle: TextStyle(color: Colors.grey[800]),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        prefixIcon: Icon(
                          Icons.arrow_drop_down_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(child: Text("Furto"), value: "Furto"),
                        DropdownMenuItem(
                          child: Text("Consumo"),
                          value: "Consumo",
                        ),
                        DropdownMenuItem(
                          child: Text("Outros"),
                          value: "Outros",
                        ),
                      ],
                      onChanged: (value) {
                        controller.selectedDropDownItem.value = value
                            .toString();
                        controller.selectedDropDownItem.value != "Outros"
                            ? controller.othersSelectedDrpDownItemController
                                  .clear()
                            : null;
                      },

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um tipo de ocorrido.';
                        }
                        return null;
                      },
                    ),
                    controller.selectedDropDownItem.value == "Outros"
                        ? HomeTextFormField(
                            hintText: "Descreva o ocorrido.",
                            iconData: Icons.library_books_sharp,
                            controller:
                                controller.othersSelectedDrpDownItemController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira um tipo de ocorrido.';
                              }
                              return null;
                            },
                          )
                        : SizedBox(),
                  ],
                );
              }),
              HomeTextFormField(
                hintText: "Código do(s) produto(s).",
                iconData: Icons.onetwothree,
                controller: controller.eansController,
                textInputType: TextInputType.numberWithOptions(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um código.';
                  }
                  return null;
                },
              ),

              HomeTextFormField(
                hintText: "Busca na pasta Retratos",
                controller: controller.searchController,
                iconData: Icons.folder_open,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um diretório.';
                  }
                  return null;
                },
                isSuffixIcon: true,
                suffixIconOnPressed: () => controller.searchFile(context),
              ),

              Obx(() {
                if (controller.isLoadingSmb.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.files.isEmpty) {
                  return const Center(
                    child: Text("Nenhum arquivo ou pasta para exibir."),
                  );
                }
                return ListView.builder(
                  itemCount: controller.files.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final file = controller.files[index];
                    final name = file.name;

                    return Obx(() {
                      return ListTile(
                        selected: controller.isSelected(file).value,
                        selectedColor: Colors.white,
                        trailing: Checkbox(
                          value: controller.isSelected(file).value,
                          onChanged: (value) =>
                              controller.toggleSelection(file),
                        ),
                        leading: Icon(
                          file.isDirectory()
                              ? Icons.folder
                              : controller.getIconForFile(name),
                          color: file.isDirectory()
                              ? Colors.amber
                              : Colors.white,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Tamanho: ${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB",
                          style: TextStyle(color: Colors.white60),
                        ),
                        onTap: () {
                          print("Arquivo clicado: ${file.name}");
                          print("Caminho completo no Samba: ${file.path}");
                          if (file.isDirectory()) {
                            controller.searchController.text = file.path.split(
                              "192.168.1.5",
                            )[1];
                            controller.searchFile(context);
                          } else {
                            controller.toggleSelection(file);
                          }
                        },
                      );
                    });
                  },
                );
              }),
              HomeTextFormField(
                hintText: "Descrição do que ocorreu.",
                iconData: Icons.description,
                controller: controller.descriptionController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição.';
                  }
                  return null;
                },
              ),
              SizedBox(height: height * 0.02),
              Obx(() {
                return SizedBox(
                  width: width,
                  height: height / 15,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.formKey.currentState!.validate()) {
                        controller.showDialog(() async {
                          var authenticated = await controller.validateUser(
                            controller.userController.text,
                            controller.passwordController.text,
                          );

                          if (authenticated == true) {
                            String userAuthenticated =
                                controller.userController.text;
                            final extensoes = ['.png', '.jpg', '.jpeg'];
                            final dateFormatted = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(DateTime.now());

                            final retrato = RetratoModel(
                              title: controller.titleController.text,
                              caseOcurrent:
                                  controller.selectedDropDownItem.value !=
                                      "Outros"
                                  ? controller.selectedDropDownItem.value!
                                  : controller
                                        .othersSelectedDrpDownItemController
                                        .text,
                              date: controller.dateController.text,
                              eans: controller.eansController.text,
                              description:
                                  controller.descriptionController.text,
                              photos: controller.selectedFilesPaths
                                  .where(
                                    (path) => extensoes.any(
                                      (ext) => path.toLowerCase().endsWith(ext),
                                    ),
                                  )
                                  .toList(),
                              videos: controller.selectedFilesPaths
                                  .where(
                                    (path) => !extensoes.any(
                                      (ext) => path.toLowerCase().endsWith(ext),
                                    ),
                                  )
                                  .toList(),
                              portraitMadeBy:
                                  '$userAuthenticated às $dateFormatted',
                              createdAt: dateFormatted,
                              isActive: true,
                            );

                            await controller.addRetrato(retrato);

                            controller.userController.clear();
                            controller.passwordController.clear();
                          }
                        });
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.red.shade900,
                      ),
                    ),
                    child: controller.isLoadingFirebase.value
                        ? Center(child: CircularProgressIndicator())
                        : Text(
                            "Salvar",
                            style: TextStyle(
                              fontSize: width / 20,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                );
              }),
              SizedBox(height: height * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
