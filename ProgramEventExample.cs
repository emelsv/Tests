using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication3
{
    class Program
    {
        static void Main(string[] args)
        {
            CTest ct = new CTest();
            ct.ValueChangeHandler += Program_ValueChanged;

            ct.Value = 100;
            ct.Value = 200;
            ct.Value = 300;

            Console.ReadLine();
        }

        public static void Program_ValueChanged(object sender, ValueChangedEventArgs e)
        {
            Console.WriteLine("Event  handled.");
        }
    }

    public class CTest
    {
        private int _value;

        public event EventHandler<ValueChangedEventArgs> ValueChangeHandler;
        public int Value 
        { 
            get { return _value; } 
            set
            {
                ValueChangedEventArgs ea = new ValueChangedEventArgs();
                _value = value;
                OnValueChanged(ea);
            } 
        }

        protected virtual void OnValueChanged(ValueChangedEventArgs e)
        {
            ValueChangeHandler?.Invoke(this, e);
        }
    }

    public class ValueChangedEventArgs : EventArgs
    {
    }
}
