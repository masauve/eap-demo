package com.example.eap.rest;

import com.example.eap.model.Task;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.net.URI;
import java.util.List;

@Path("/tasks")
@ApplicationScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TaskResource {

    @PersistenceContext
    private EntityManager em;

    @GET
    public List<Task> list() {
        return em.createQuery("SELECT t FROM Task t ORDER BY t.id", Task.class)
                .getResultList();
    }

    @GET
    @Path("/{id}")
    public Response get(@PathParam("id") Long id) {
        Task task = em.find(Task.class, id);
        if (task == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(task).build();
    }

    @POST
    @Transactional
    public Response create(@Valid Task task) {
        em.persist(task);
        return Response.created(URI.create("/api/tasks/" + task.getId()))
                .entity(task)
                .build();
    }

    @PUT
    @Path("/{id}")
    @Transactional
    public Response update(@PathParam("id") Long id, @Valid Task updated) {
        Task task = em.find(Task.class, id);
        if (task == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        task.setTitle(updated.getTitle());
        task.setDescription(updated.getDescription());
        task.setCompleted(updated.isCompleted());
        em.merge(task);
        return Response.ok(task).build();
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public Response delete(@PathParam("id") Long id) {
        Task task = em.find(Task.class, id);
        if (task == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        em.remove(task);
        return Response.noContent().build();
    }
}
