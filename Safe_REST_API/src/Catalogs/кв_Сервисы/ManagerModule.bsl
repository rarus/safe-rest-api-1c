///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022-2025, ООО 1С-Рарус
// Все права защищены. Эта программа и сопроводительные материалы предоставляются
// в соответствии с условиями лицензии Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by-sa/4.0/legalcode
//////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Возвращает настройки контроля сервиса
//
// Параметры:
//  ИмяСервиса - Строка - имя сервиса
// 
// Возвращаемое значение:
//   - Структура - настройки контроля сервиса 
//
Функция НастройкиСервиса(ИмяСервиса) Экспорт
	
	Префикс = "HTTP-сервис: ";
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("ИмяСервиса", ИмяСервиса);
	Запрос.УстановитьПараметр("Префикс", Префикс);
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	кв_Сервисы.Ссылка КАК Сервис,
	|	кв_Сервисы.Наименование КАК Наименование,
	|	кв_Сервисы.ПометкаУдаления КАК ПометкаУдаления,
	|	кв_Сервисы.Используется КАК Используется,
	|	кв_Сервисы.Журналирование
	|		И НЕ кв_Сервисы.ПометкаУдаления КАК Журналирование,
	|	кв_Сервисы.РегистрироватьТелоЗапроса КАК РегистрироватьТелоЗапроса,
	|	кв_Сервисы.РегистрироватьТелоОтвета КАК РегистрироватьТелоОтвета,
	|	кв_Сервисы.ОбеспечениеИдемпотентности
	|		И НЕ кв_Сервисы.ПометкаУдаления КАК ОбеспечениеИдемпотентности,
	|	кв_Сервисы.КонтрольКонфликтовЗапросов
	|		И НЕ кв_Сервисы.ПометкаУдаления КАК КонтрольКонфликтовЗапросов,
	|	кв_Сервисы.ПорогРазблокировкиКонфликтов КАК ПорогРазблокировкиКонфликтов,
	|	кв_Сервисы.ПовторовДоРазблокировкиКонфликтов КАК ПовторовДоРазблокировкиКонфликтов,
	|	кв_Сервисы.ПериодПроверкиПорогаРазблокировки КАК ПериодПроверкиПорогаРазблокировки,
	|	кв_Сервисы.ДнейХраненияЗаписейЖурналов КАК ДнейХраненияЗаписейЖурналов,
	|	кв_Сервисы.ПериодГарантированнойРазблокировки КАК ПериодГарантированнойРазблокировки,
	|	кв_Сервисы.МаксимальнаяДлинаТелаЗапроса КАК МаксимальнаяДлинаТелаЗапроса,
	|	&Префикс + кв_Сервисы.Наименование КАК ИмяСобытия
	|ИЗ
	|	Справочник.кв_Сервисы КАК кв_Сервисы
	|ГДЕ
	|	кв_Сервисы.Наименование = &ИмяСервиса
	|
	|УПОРЯДОЧИТЬ ПО
	|	кв_Сервисы.ПометкаУдаления,
	|	кв_Сервисы.Используется УБЫВ";
	
	УстановитьПривилегированныйРежим(Истина);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	НастройкиСервиса = ОписаниеСтруктурыПоРезультатуЗапроса(РезультатЗапроса, Ложь);
	
	Выборка = РезультатЗапроса.Выбрать();
	Если Выборка.Следующий() Тогда
		ЗаполнитьЗначенияСвойств(НастройкиСервиса, Выборка);
	КонецЕсли;
	
	Возврат НастройкиСервиса;
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Формирует структуру по колонкам результата запроса
//
// Параметры:
//  РезультатЗапроса - РезультатЗапроса	 - Результат запроса.
//  ЗначениеПоУмолчанию - Произвольный - произвольное значение по умолчанию.
// 
// Возвращаемое значение:
//   - Структура - структура с именами элементов по именам колонок из результата запроса
//
Функция ОписаниеСтруктурыПоРезультатуЗапроса(РезультатЗапроса, ЗначениеПоУмолчанию = Неопределено)
	
	ОписаниеСтруктуры = Новый Структура;
	Для каждого КолонкаРезультата Из РезультатЗапроса.Колонки Цикл
		ОписаниеСтруктуры.Вставить(КолонкаРезультата.Имя, ЗначениеПоУмолчанию);
	КонецЦикла; 
	
	Возврат ОписаниеСтруктуры;
	
КонецФункции 

#КонецОбласти

#КонецЕсли
