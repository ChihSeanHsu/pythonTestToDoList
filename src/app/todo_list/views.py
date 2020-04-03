import json

from django.shortcuts import render, HttpResponse
from django.views.generic import TemplateView
from django.core.mail import send_mail

from .models import ToDoList

# Create your views here.
class HomePage(TemplateView):
    template_name = 'home.html'

    def get(self, request, *args, **kwargs):
        if 'to_do' not in request.session:
            request.session['to_do'] = []
        to_do_list = request.session['to_do']

        return render(request, self.template_name, { 'to_do_list': to_do_list })

    def post(self, request, *args, **kwargs):
        if 'to_do' not in request.session:
            request.session['to_do'] = []
        new_item = request.POST.get('new_item')
        to_do_list = request.session['to_do']
        to_do_list.append(new_item)
        request.session['to_do'] = to_do_list

        return render(request, self.template_name, { 'to_do_list': to_do_list })

def save_todo_list(request):
    email = request.POST.get('email')
    to_do_list = request.session.get('to_do', [])
    todo_ins = ToDoList.objects.create(
        email=email,
        to_do_list=json.dumps(to_do_list)
    )
    todo_ins.save()

    subject = 'Your Todo list'
    msg = f'Click here to get your list {request.scheme}://{request.get_host()}/?key={todo_ins.key}'
    from_who = 'TODO_LIST'
    to_who = [email]
    send_mail(
        subject,
        msg,
        from_who,
        to_who,

    )

    return HttpResponse(todo_ins.key)