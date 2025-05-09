///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022-2025, ООО 1С-Рарус
// Все права защищены. Эта программа и сопроводительные материалы предоставляются
// в соответствии с условиями лицензии Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by-sa/4.0/legalcode
//////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ОбработчикиСобытий

Процедура ОбработкаЗаполнения(ДанныеЗаполнения, ТекстЗаполнения, СтандартнаяОбработка)
	
	Если ТипЗнч(ДанныеЗаполнения) = Тип("Структура") Тогда
		ЗаполнитьЗначенияСвойств(ЭтотОбъект, ДанныеЗаполнения);
	КонецЕсли;
		
КонецПроцедуры

Процедура ПередЗаписью(Отказ)
	
	Если ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;
	
	ПроверитьНаличиеПартнераПоИНН(Отказ);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ПроверитьНаличиеПартнераПоИНН(Отказ)
	
	Если НЕ ЭтоНовый() Тогда
		Возврат;
	КонецЕсли;
	
	ИспользоватьПроверку = Константы._ДемоИспользоватьПроверкуПартнераПередЗаписью.Получить();
	Если НЕ ИспользоватьПроверку Тогда
		Возврат;
	КонецЕсли;
	
	ПартнерИБ = Справочники._ДемоПартнеры.ПартнерПоИНН(ИНН);
	
	Если ЗначениеЗаполнено(ПартнерИБ) Тогда
		
		ИмяСобытия = НСтр("ru = 'Создание партнера'");
		Шаблон = НСтр("ru = 'Партнер с ИНН %1 уже есть в базе'");
		ТекстСообщения = СтрШаблон(Шаблон, СокрП(ИНН));
		
		ЗаписьЖурналаРегистрации(
			ИмяСобытия,
			УровеньЖурналаРегистрации.Ошибка,
			Метаданные.Справочники._ДемоПартнеры, ,
			ТекстСообщения);
			
		кв_ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения, , "ИНН", "Объект", Отказ);
			
	КонецЕсли;

КонецПроцедуры

#КонецОбласти
